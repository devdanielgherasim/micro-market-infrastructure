locals {
  platform_secret_payloads = {
    "postgresql-auth" = {
      username          = "microservices_owner"
      password          = random_password.postgresql_owner.result
      postgres-password = random_password.postgresql_owner.result
      database          = var.database_name
    }
    "keycloak-postgresql" = {
      username          = "keycloak"
      password          = random_password.keycloak_db.result
      POSTGRES_USER     = "keycloak"
      POSTGRES_PASSWORD = random_password.keycloak_db.result
      POSTGRES_DB       = "keycloak"
      POSTGRES_HOST     = "postgresql.postgresql.svc.cluster.local"
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
      DOMAIN                     = "danielgherasim.com"
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
      username = "catalog"
      password = random_password.catalog_db.result
    }
    "orders-db" = {
      username = "orders"
      password = random_password.orders_db.result
    }
    "audit-db" = {
      username = "audit"
      password = random_password.audit_db.result
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

resource "random_password" "keycloak_db" {
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

resource "google_secret_manager_secret" "platform" {
  for_each = local.platform_secret_payloads

  secret_id = "${var.project_name}-${var.environment}-${each.key}"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret_version" "platform" {
  for_each = local.platform_secret_payloads

  secret      = google_secret_manager_secret.platform[each.key].id
  secret_data = jsonencode(each.value)
}

resource "google_secret_manager_secret_iam_member" "platform_external_secrets_accessor" {
  for_each = google_secret_manager_secret.platform

  project   = var.project_id
  secret_id = each.value.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.addon["external_secrets"].email}"
}
