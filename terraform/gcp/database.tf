locals {
  db_admin_username = "microservicesowner"
}

# Private Service Access for Cloud SQL — allocates a /20 from the default VPC
# for Google-managed services and peers it, so Cloud SQL gets a private IP
# reachable from GKE without any public exposure.
data "google_compute_network" "default" {
  name    = "default"
  project = var.project_id
}

resource "google_compute_global_address" "private_ip_range" {
  name          = local.naming.sql_private_ip_range
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = data.google_compute_network.default.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = data.google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_sql_database_instance" "postgresql" {
  name             = local.naming.cloud_sql_instance
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

    database_flags {
      name  = "cloudsql.enable_pgaudit"
      value = "on"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_duration"
      value = "on"
    }

    database_flags {
      name  = "log_error_verbosity"
      value = "default"
    }

    database_flags {
      name  = "log_hostname"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    database_flags {
      name  = "log_min_error_statement"
      value = "error"
    }

    database_flags {
      name  = "log_min_messages"
      value = "error"
    }

    database_flags {
      name  = "log_statement"
      value = "ddl"
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.default.id
      ssl_mode        = "ENCRYPTED_ONLY"
    }
  }

  deletion_protection = var.deletion_protection

  depends_on = [google_service_networking_connection.private_vpc]
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
