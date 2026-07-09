locals {
  db_admin_username = "microservicesowner"
}

resource "google_sql_database_instance" "postgresql" {
  name             = "pg-${var.project_name}-${var.environment}"
  database_version = "POSTGRES_16"
  region           = var.region
  project          = var.project_id

  settings {
    tier              = "db-f1-micro"
    availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    disk_type         = "PD_HDD"
    disk_size         = 10
    disk_autoresize   = true

    backup_configuration {
      enabled = var.environment == "prod"
    }

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "kubernetes-egress"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = var.deletion_protection
}

resource "google_sql_database" "microservices" {
  name     = var.database_name
  instance = google_sql_database_instance.postgresql.name
  project  = var.project_id
}

resource "google_sql_user" "postgresql_owner" {
  name     = local.db_admin_username
  instance = google_sql_database_instance.postgresql.name
  password = random_password.postgresql_owner.result
  project  = var.project_id
}

