# Keycloak on GCP Cloud Run v2 (ADR-19). Design/IaC-only in this pass: GCP is
# not currently the active cloud (ADR-1, clouds run one at a time), so this
# is not applied or live-validated here - only fmt/validate.
#
# Pulls quay.io/keycloak/keycloak:26.3.1 directly (Cloud Run's generic
# registry support), matching the Azure leg and the prior in-cluster
# behavior - no Artifact Registry mirroring, unlike AWS App Runner which has
# a hard ECR-only constraint. VERIFY DURING IMPLEMENTATION: the Terraform
# provider's own field description for `image` says "Google Container
# Registry or Google Artifact Registry," which is narrower than Cloud Run's
# actual product capability (arbitrary public registries) as of this
# writing - confirm against a real deploy before relying on it.
#
# DB connectivity uses the already-public Cloud SQL IP + password auth (see
# database.tf: authorized_networks = 0.0.0.0/0) rather than the Cloud SQL
# Auth Proxy volume-mount integration, since that requires a Postgres Socket
# Factory JDBC driver not bundled in the stock Keycloak image - deferred
# hardening item, not adopted here.
#
# Secrets: same constraint as the Azure leg - Cloud Run's native
# secret_key_ref maps one Secret Manager secret version to one env var and
# cannot split the existing `keycloak-postgresql`/`keycloak-admin` JSON
# blobs. Decoded via a Terraform data source instead, for the same reasons
# documented in azure/keycloak_paas.tf.

data "google_secret_manager_secret_version" "keycloak_postgresql" {
  secret = google_secret_manager_secret.platform["keycloak-postgresql"].secret_id

  depends_on = [google_secret_manager_secret_version.platform]
}

data "google_secret_manager_secret_version" "keycloak_admin" {
  secret = google_secret_manager_secret.platform["keycloak-admin"].secret_id

  depends_on = [google_secret_manager_secret_version.platform]
}

locals {
  keycloak_hostname     = "auth.danielgherasim.com"
  keycloak_db_secret    = jsondecode(data.google_secret_manager_secret_version.keycloak_postgresql.secret_data)
  keycloak_admin_secret = jsondecode(data.google_secret_manager_secret_version.keycloak_admin.secret_data)
}

# min=max=1 instance: no built-in HA, matching ADR-19's cross-cloud decision
# (Keycloak's JGroups/KUBE_PING clustering has no equivalent here).
resource "google_cloud_run_v2_service" "keycloak" {
  name                = "${local.cluster_name}-keycloak"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  labels              = local.common_labels

  template {
    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    containers {
      name  = "keycloak"
      image = "quay.io/keycloak/keycloak:26.3.1"

      # See azure/keycloak_paas.tf for the same "verify during
      # implementation" caveat on the exact Keycloak 26.x startup flags.
      args = ["start", "--http-enabled=true", "--proxy-headers=xforwarded"]

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      env {
        name  = "KC_DB"
        value = "postgres"
      }
      env {
        name  = "KC_DB_URL_HOST"
        value = local.keycloak_db_secret.POSTGRES_HOST
      }
      env {
        name  = "KC_DB_URL_PORT"
        value = local.keycloak_db_secret.POSTGRES_PORT
      }
      env {
        name  = "KC_DB_URL_DATABASE"
        value = local.keycloak_db_secret.POSTGRES_DB
      }
      env {
        name  = "KC_DB_USERNAME"
        value = local.keycloak_db_secret.POSTGRES_USER
      }
      env {
        name  = "KC_DB_PASSWORD"
        value = local.keycloak_db_secret.POSTGRES_PASSWORD
      }
      env {
        name  = "KC_BOOTSTRAP_ADMIN_USERNAME"
        value = local.keycloak_admin_secret.username
      }
      env {
        name  = "KC_BOOTSTRAP_ADMIN_PASSWORD"
        value = local.keycloak_admin_secret.password
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

      startup_probe {
        http_get {
          path = "/auth/health/ready"
          port = 8080
        }
        initial_delay_seconds = 10
        period_seconds        = 10
        failure_threshold     = 12
      }
      liveness_probe {
        http_get {
          path = "/auth/health/live"
          port = 8080
        }
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Cloud Run defaults to requiring an authenticated caller; Keycloak's OIDC
# endpoints (and the app services validating tokens against them) need to be
# reachable publicly, so this grants unauthenticated invocation explicitly
# rather than relying on a project-level default.
resource "google_cloud_run_v2_service_iam_member" "keycloak_public" {
  location = google_cloud_run_v2_service.keycloak.location
  name     = google_cloud_run_v2_service.keycloak.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Domain mapping additionally requires the domain to already be verified for
# this GCP project/organization via Search Console - a one-time, manual,
# out-of-band step Terraform cannot perform. Not exercised in this pass
# since GCP isn't applied. VERIFY DURING IMPLEMENTATION: whether the fully
# managed domain mapping GA path used here is still the recommended
# approach in the target region, vs. the heavier Serverless NEG + external
# HTTPS Load Balancer alternative Google's own docs steer newer
# integrations toward.
resource "google_cloud_run_domain_mapping" "keycloak" {
  location = var.region
  name     = local.keycloak_hostname

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.keycloak.name
  }
}
