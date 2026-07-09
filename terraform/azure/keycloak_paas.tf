# Keycloak moved off the AKS cluster onto Azure Container Apps (ADR-19).
# Design: min=max=1 replica (no built-in HA — see ADR-19 consequences), the
# stock quay.io/keycloak/keycloak image pulled directly (same image the
# in-cluster CR used; not mirrored into ACR, since it's a public third-party
# image and no other part of this repo mirrors third-party images). DB/admin
# credentials are decoded from the existing `keycloak-postgresql`/
# `keycloak-admin` Key Vault JSON blobs at apply time (secrets.tf) and passed
# as literal Container App secrets, because Container Apps' native
# key_vault_secret_id reference maps one KV secret to one env var and cannot
# split a JSON blob the way ESO's `property:` extraction could — introducing
# per-field flat KV secrets just for this would be more moving parts than a
# lab-scope migration warrants. No managed identity is required as a result:
# the image is public and secrets are resolved by Terraform, not at runtime.

data "azurerm_key_vault_secret" "keycloak_postgresql" {
  name         = "keycloak-postgresql"
  key_vault_id = azurerm_key_vault.platform.id

  depends_on = [azurerm_key_vault_secret.platform]
}

data "azurerm_key_vault_secret" "keycloak_admin" {
  name         = "keycloak-admin"
  key_vault_id = azurerm_key_vault.platform.id

  depends_on = [azurerm_key_vault_secret.platform]
}

locals {
  keycloak_hostname     = "auth.danielgherasim.com"
  keycloak_db_secret    = jsondecode(data.azurerm_key_vault_secret.keycloak_postgresql.value)
  keycloak_admin_secret = jsondecode(data.azurerm_key_vault_secret.keycloak_admin.value)
}

resource "azurerm_log_analytics_workspace" "keycloak" {
  # Short, environment-scoped names (not the usual "${local.cluster_name}-*"
  # pattern): Container Apps enforces a 32-char name limit, and
  # local.cluster_name alone ("k8s-danielgherasim-microservices-dev") is
  # already 36 chars - discovered live when azurerm_container_app.keycloak's
  # name was rejected. RG-scoped uniqueness is enough here (unlike ACR/Key
  # Vault, which need global uniqueness), so "keycloak-<env>" is sufficient.
  name                = "log-keycloak-${var.environment}"
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
  name                       = "keycloak-env-${var.environment}"
  location                   = var.secondary_location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.keycloak.id
  tags                       = local.tags
}

resource "azurerm_container_app" "keycloak" {
  name                         = "keycloak-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.keycloak.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"
  tags                         = local.tags

  secret {
    name  = "db-host"
    value = local.keycloak_db_secret.POSTGRES_HOST
  }
  secret {
    name  = "db-port"
    value = local.keycloak_db_secret.POSTGRES_PORT
  }
  secret {
    name  = "db-name"
    value = local.keycloak_db_secret.POSTGRES_DB
  }
  secret {
    name  = "db-username"
    value = local.keycloak_db_secret.POSTGRES_USER
  }
  secret {
    name  = "db-password"
    value = local.keycloak_db_secret.POSTGRES_PASSWORD
  }
  secret {
    name  = "admin-username"
    value = local.keycloak_admin_secret.username
  }
  secret {
    name  = "admin-password"
    value = local.keycloak_admin_secret.password
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

  name                         = "keycloak-cert-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.keycloak.id
  subject_name                 = local.keycloak_hostname
  domain_control_validation    = "CNAME"
  tags                         = local.tags

  depends_on = [azurerm_container_app_custom_domain.keycloak]
}
