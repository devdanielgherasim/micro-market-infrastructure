data "azurerm_client_config" "current" {}

locals {
  platform_secret_payloads = {
    "postgresql-auth" = {
      username          = local.db_admin_username
      password          = random_password.postgresql_owner.result
      postgres-password = random_password.postgresql_owner.result
      database          = var.database_name
      host              = azurerm_postgresql_flexible_server.postgresql.fqdn
      port              = "5432"
    }
    "keycloak-postgresql" = {
      username          = local.db_admin_username
      password          = random_password.postgresql_owner.result
      POSTGRES_USER     = local.db_admin_username
      POSTGRES_PASSWORD = random_password.postgresql_owner.result
      POSTGRES_DB       = var.database_name
      POSTGRES_HOST     = azurerm_postgresql_flexible_server.postgresql.fqdn
      POSTGRES_PORT     = "5432"
    }
    "keycloak-admin" = {
      username = "admin"
      password = random_password.keycloak_admin.result
    }
    "keycloak-clients" = {
      audit-service-secret   = random_password.audit_client.result
      catalog-service-secret = random_password.catalog_client.result
      orders-service-secret  = random_password.orders_client.result
      argocd-client-secret   = random_password.argocd_client.result
      grafana-client-secret  = random_password.grafana_oidc_client.result
      kiali-client-secret    = random_password.kiali_oidc_client.result
      microservices-app      = random_password.microservices_app_client.result
    }
    "grafana-admin" = {
      admin-user     = "admin"
      admin-password = random_password.grafana_admin.result
    }
    "grafana-oauth" = {
      GRAFANA_OIDC_CLIENT_SECRET = random_password.grafana_oidc_client.result
      SMTP_PASSWORD              = random_password.smtp.result
      DOMAIN                     = var.dns_domain
    }
    "alertmanager-smtp" = {
      SMTP_HOST     = "smtp.gmail.com:587"
      SMTP_USERNAME = "alertmanager@monitoring.local"
      SMTP_PASSWORD = random_password.alertmanager_smtp.result
      SMTP_FROM     = "alertmanager@monitoring.local"
    }
    "loki-auth" = {
      LOKI_PASSWORD = random_password.loki.result
    }
    "cloudflare-api-token" = {
      api-token = var.cloudflare_api_token
    }
    "argocd-admin" = {
      password = random_password.argocd_admin.result
    }
    "argocd-redis" = {
      password = random_password.argocd_redis.result
    }
    "catalog-db" = {
      username = "catalog_svc"
      password = random_password.catalog_db.result
      host     = azurerm_postgresql_flexible_server.postgresql.fqdn
      port     = "5432"
      database = var.database_name
    }
    "orders-db" = {
      username = "orders_svc"
      password = random_password.orders_db.result
      host     = azurerm_postgresql_flexible_server.postgresql.fqdn
      port     = "5432"
      database = var.database_name
    }
    "audit-db" = {
      username = "audit_svc"
      password = random_password.audit_db.result
      host     = azurerm_postgresql_flexible_server.postgresql.fqdn
      port     = "5432"
      database = var.database_name
    }
    "microservices-keycloak" = {
      audit-service-secret   = random_password.audit_client.result
      catalog-service-secret = random_password.catalog_client.result
      orders-service-secret  = random_password.orders_client.result
    }
  }
}

resource "random_password" "postgresql_owner" {
  length  = 24
  special = false
}

# Per-service DB passwords — least-privilege: each microservice gets its own
# credential instead of sharing the admin/owner password.
resource "random_password" "catalog_db" {
  length  = 24
  special = false
}

resource "random_password" "orders_db" {
  length  = 24
  special = false
}

resource "random_password" "audit_db" {
  length  = 24
  special = false
}

resource "random_password" "keycloak_admin" {
  length  = 24
  special = false
}

resource "random_password" "catalog_client" {
  length  = 32
  special = false
}

resource "random_password" "orders_client" {
  length  = 32
  special = false
}

resource "random_password" "audit_client" {
  length  = 32
  special = false
}

resource "random_password" "argocd_client" {
  length  = 32
  special = false
}

resource "random_password" "grafana_oidc_client" {
  length  = 32
  special = false
}

resource "random_password" "kiali_oidc_client" {
  length  = 32
  special = false
}

resource "random_password" "microservices_app_client" {
  length  = 32
  special = false
}

resource "random_password" "grafana_admin" {
  length  = 24
  special = true
}

resource "random_password" "smtp" {
  length  = 24
  special = true
}

resource "random_password" "alertmanager_smtp" {
  length  = 24
  special = true
}

resource "random_password" "loki" {
  length  = 24
  special = true
}

resource "random_password" "argocd_admin" {
  length      = 24
  special     = true
  min_special = 2
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "random_password" "argocd_redis" {
  length      = 24
  special     = true
  min_special = 2
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
}

resource "azurerm_key_vault" "platform" {
  name                       = local.naming.key_vault
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  tags                       = local.tags
}

resource "azurerm_role_assignment" "terraform_key_vault" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.platform.id
}

resource "azurerm_key_vault_secret" "platform" {
  for_each = local.platform_secret_payloads

  name         = each.key
  value        = jsonencode(each.value)
  key_vault_id = azurerm_key_vault.platform.id
  content_type = "application/json"
  tags         = local.tags

  depends_on = [azurerm_role_assignment.terraform_key_vault]
}
