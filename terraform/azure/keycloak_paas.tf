# Keycloak moved off the AKS cluster onto Azure Container Apps (ADR-19).
# Design: min=max=1 replica (no built-in HA — see ADR-19 consequences), the
# stock quay.io/keycloak/keycloak image pulled directly (same image the
# in-cluster CR used; not mirrored into ACR, since it's a public third-party
# image and no other part of this repo mirrors third-party images).
#
# Secrets are live Key Vault references (key_vault_secret_id), not literal
# values baked at apply time. A dedicated user-assigned managed identity
# (keycloak_container_app) with Key Vault Secrets User role lets the
# Container App runtime pull secrets directly from Key Vault. Rotation only
# requires updating the Key Vault secret value — the Container App picks up
# the new value on the next revision restart, no terraform apply needed.

locals {
  keycloak_hostname = "auth.danielgherasim.com"

  # Individual flat Key Vault secrets for Keycloak's Container App.
  # These replace the JSON-blob approach so each secret can be referenced
  # directly via key_vault_secret_id on the Container App.
  keycloak_kv_secrets = {
    "keycloak-db-host"     = azurerm_postgresql_flexible_server.postgresql.fqdn
    "keycloak-db-port"     = "5432"
    "keycloak-db-name"     = var.database_name
    "keycloak-db-username" = local.db_admin_username
    "keycloak-db-password" = random_password.postgresql_owner.result
    "keycloak-admin-user"  = "admin"
    "keycloak-admin-pass"  = random_password.keycloak_admin.result
  }
}

resource "azurerm_key_vault_secret" "keycloak" {
  for_each = local.keycloak_kv_secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.platform.id
  content_type = "text/plain"

  depends_on = [azurerm_role_assignment.terraform_key_vault]
}

# Managed identity for the Keycloak Container App to pull secrets from
# Key Vault at runtime (not at Terraform apply time).
resource "azurerm_user_assigned_identity" "keycloak_container_app" {
  name                = "${local.naming.container_app}-identity"
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "keycloak_kv_secrets_user" {
  principal_id         = azurerm_user_assigned_identity.keycloak_container_app.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.platform.id
}

resource "azurerm_log_analytics_workspace" "keycloak" {
  # Short, environment-scoped names (not the usual "${local.cluster_name}-*"
  # pattern): Container Apps enforces a 32-char name limit, and
  # local.cluster_name alone ("k8s-danielgherasim-microservices-dev") is
  # already 36 chars - discovered live when azurerm_container_app.keycloak's
  # name was rejected. RG-scoped uniqueness is enough here (unlike ACR/Key
  # Vault, which need global uniqueness), so "keycloak-<env>" is sufficient.
  name                = local.naming.log_analytics_workspace
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# No `workload_profile` block: an environment created without one is
# Consumption-only, which is the cheapest tier and matches the "genuine
# perpetual free consumption grant" this cloud/product was chosen for.
resource "azurerm_container_app_environment" "keycloak" {
  name                       = local.naming.container_app_environment
  location                   = var.secondary_location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.keycloak.id
  tags                       = local.tags
}

resource "azurerm_container_app" "keycloak" {
  name                         = local.naming.container_app
  container_app_environment_id = azurerm_container_app_environment.keycloak.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.keycloak_container_app.id]
  }

  # Live Key Vault references — the Container App runtime pulls these
  # directly from Key Vault using the managed identity above. Updating
  # a secret in Key Vault takes effect on the next revision restart,
  # no terraform apply required.
  secret {
    name                = "db-host"
    key_vault_secret_id = azurerm_key_vault_secret.keycloak["keycloak-db-host"].versionless_id
    identity            = azurerm_user_assigned_identity.keycloak_container_app.id
  }
  secret {
    name                = "db-port"
    key_vault_secret_id = azurerm_key_vault_secret.keycloak["keycloak-db-port"].versionless_id
    identity            = azurerm_user_assigned_identity.keycloak_container_app.id
  }
  secret {
    name                = "db-name"
    key_vault_secret_id = azurerm_key_vault_secret.keycloak["keycloak-db-name"].versionless_id
    identity            = azurerm_user_assigned_identity.keycloak_container_app.id
  }
  secret {
    name                = "db-username"
    key_vault_secret_id = azurerm_key_vault_secret.keycloak["keycloak-db-username"].versionless_id
    identity            = azurerm_user_assigned_identity.keycloak_container_app.id
  }
  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.keycloak["keycloak-db-password"].versionless_id
    identity            = azurerm_user_assigned_identity.keycloak_container_app.id
  }
  secret {
    name                = "admin-username"
    key_vault_secret_id = azurerm_key_vault_secret.keycloak["keycloak-admin-user"].versionless_id
    identity            = azurerm_user_assigned_identity.keycloak_container_app.id
  }
  secret {
    name                = "admin-password"
    key_vault_secret_id = azurerm_key_vault_secret.keycloak["keycloak-admin-pass"].versionless_id
    identity            = azurerm_user_assigned_identity.keycloak_container_app.id
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "keycloak"
      image  = "quay.io/keycloak/keycloak:26.3.1"
      cpu    = 0.5
      memory = "1Gi"

      # Startup flags/env are a best-effort port of the in-cluster Keycloak
      # CR's config (db.vendor postgres, httpRelativePath /auth,
      # hostname.strict true) to the plain-container equivalent. Container
      # Apps ingress terminates TLS and forwards HTTP internally, hence
      # http-enabled + proxy-headers=xforwarded. VERIFY DURING
      # IMPLEMENTATION against a real container start — Keycloak 26.x's
      # exact hostname/proxy flag combination for a path-prefixed, TLS-
      # terminated-upstream deployment was not validated against a live
      # instance while writing this.
      args = ["start", "--http-enabled=true", "--proxy-headers=xforwarded"]

      env {
        name  = "KC_DB"
        value = "postgres"
      }
      env {
        name        = "KC_DB_URL_HOST"
        secret_name = "db-host"
      }
      env {
        name        = "KC_DB_URL_PORT"
        secret_name = "db-port"
      }
      env {
        name        = "KC_DB_URL_DATABASE"
        secret_name = "db-name"
      }
      env {
        name        = "KC_DB_USERNAME"
        secret_name = "db-username"
      }
      env {
        name        = "KC_DB_PASSWORD"
        secret_name = "db-password"
      }
      env {
        name        = "KC_BOOTSTRAP_ADMIN_USERNAME"
        secret_name = "admin-username"
      }
      env {
        name        = "KC_BOOTSTRAP_ADMIN_PASSWORD"
        secret_name = "admin-password"
      }
      env {
        name  = "KC_HOSTNAME"
        value = "https://${local.keycloak_hostname}/auth"
      }
      env {
        name  = "KC_HOSTNAME_STRICT"
        value = "true"
      }
      env {
        name  = "KC_HTTP_RELATIVE_PATH"
        value = "/auth"
      }
      env {
        name  = "KC_HEALTH_ENABLED"
        value = "true"
      }
      env {
        name  = "KC_METRICS_ENABLED"
        value = "true"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/auth/health/ready"
      }
      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/auth/health/live"
      }
    }
  }
}

# Two-phase apply, matching the real ordering constraint: Container Apps
# custom-domain binding requires a `asuid.<hostname>` DNS TXT record
# (containing custom_domain_verification_id) to already resolve before the
# binding succeeds, and the managed certificate requires the custom domain
# to already be bound. That DNS record is owned by ExternalDNS/DNSEndpoint in
# platform-gitops (ADR-10), not by this Terraform root, so it can't be
# created and verified in the same apply as the Container App itself.
# Phase 1 (default): apply with keycloak_custom_domain_enabled = false,
#   read the `keycloak_custom_domain_verification_id` / `keycloak_default_hostname`
#   outputs, and use them to populate the keycloak-dns DNSEndpoint's TXT +
#   CNAME records in platform-gitops.
# Phase 2: once those records resolve, re-apply with the variable set to
#   true to bind the custom domain and provision the managed certificate.
resource "azurerm_container_app_custom_domain" "keycloak" {
  count = var.keycloak_custom_domain_enabled ? 1 : 0

  name             = local.keycloak_hostname
  container_app_id = azurerm_container_app.keycloak.id

  lifecycle {
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}

resource "azurerm_container_app_environment_managed_certificate" "keycloak" {
  count = var.keycloak_custom_domain_enabled ? 1 : 0

  name                         = local.naming.container_app_managed_cert
  container_app_environment_id = azurerm_container_app_environment.keycloak.id
  subject_name                 = local.keycloak_hostname
  domain_control_validation    = "CNAME"
  tags                         = local.tags

  depends_on = [azurerm_container_app_custom_domain.keycloak]
}
