locals {
  secret_prefix = "${var.project_name}/${var.environment}"

  platform_secret_payloads = {
    "postgresql/auth" = {
      username          = local.db_admin_username
      password          = random_password.postgresql_owner.result
      postgres-password = random_password.postgresql_owner.result
      database          = var.database_name
      host              = aws_db_instance.postgresql.address
      port              = tostring(aws_db_instance.postgresql.port)
    }
    "keycloak/postgresql" = {
      username          = local.db_admin_username
      password          = random_password.postgresql_owner.result
      POSTGRES_USER     = local.db_admin_username
      POSTGRES_PASSWORD = random_password.postgresql_owner.result
      POSTGRES_DB       = var.database_name
      POSTGRES_HOST     = aws_db_instance.postgresql.address
      POSTGRES_PORT     = tostring(aws_db_instance.postgresql.port)
    }
    "keycloak/admin" = {
      username = "admin"
      password = random_password.keycloak_admin.result
    }
    "keycloak/clients" = {
      audit-service-secret   = random_password.audit_client.result
      catalog-service-secret = random_password.catalog_client.result
      orders-service-secret  = random_password.orders_client.result
      argocd-client-secret   = random_password.argocd_client.result
      grafana-client-secret  = random_password.grafana_oidc_client.result
      kiali-client-secret    = random_password.kiali_oidc_client.result
      microservices-app      = random_password.microservices_app_client.result
    }
    "grafana/admin" = {
      admin-user     = "admin"
      admin-password = random_password.grafana_admin.result
    }
    "grafana/oauth" = {
      GRAFANA_OIDC_CLIENT_SECRET = random_password.grafana_oidc_client.result
      SMTP_PASSWORD              = random_password.smtp.result
      DOMAIN                     = "danielgherasim.com"
    }
    "alertmanager/smtp" = {
      SMTP_HOST     = "smtp.gmail.com:587"
      SMTP_USERNAME = "alertmanager@monitoring.local"
      SMTP_PASSWORD = random_password.alertmanager_smtp.result
      SMTP_FROM     = "alertmanager@monitoring.local"
    }
    "loki/auth" = {
      LOKI_PASSWORD = random_password.loki.result
    }
    "cloudflare/api-token" = {
      api-token = var.cloudflare_api_token
    }
    "argocd/admin" = {
      password = random_password.argocd_admin.result
    }
    "argocd/redis" = {
      password = random_password.argocd_redis.result
    }
    "catalog/db" = {
      username = local.db_admin_username
      password = random_password.postgresql_owner.result
      host     = aws_db_instance.postgresql.address
      port     = tostring(aws_db_instance.postgresql.port)
      database = var.database_name
    }
    "orders/db" = {
      username = local.db_admin_username
      password = random_password.postgresql_owner.result
      host     = aws_db_instance.postgresql.address
      port     = tostring(aws_db_instance.postgresql.port)
      database = var.database_name
    }
    "audit/db" = {
      username = local.db_admin_username
      password = random_password.postgresql_owner.result
      host     = aws_db_instance.postgresql.address
      port     = tostring(aws_db_instance.postgresql.port)
      database = var.database_name
    }
    "microservices/keycloak" = {
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

resource "aws_secretsmanager_secret" "platform" {
  for_each = local.platform_secret_payloads

  name                    = "${local.secret_prefix}/${each.key}"
  recovery_window_in_days = var.secrets_recovery_window_in_days
  kms_key_id              = aws_kms_key.eks_secrets.arn
}

resource "aws_secretsmanager_secret_version" "platform" {
  for_each = local.platform_secret_payloads

  secret_id     = aws_secretsmanager_secret.platform[each.key].id
  secret_string = jsonencode(each.value)
}
