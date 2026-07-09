mock_provider "google" {}
mock_provider "google-beta" {}

override_data {
  target = data.google_client_config.default
  values = {
    access_token = "test-token"
  }
}

override_data {
  target = data.google_container_cluster.this
  values = {
    endpoint               = "127.0.0.1"
    cluster_ca_certificate = "test-ca"
  }
}

override_data {
  target = data.google_secret_manager_secret_version.keycloak_postgresql
  values = {
    secret_data = "{\"POSTGRES_HOST\":\"localhost\",\"POSTGRES_PORT\":\"5432\",\"POSTGRES_DB\":\"microservices\",\"POSTGRES_USER\":\"microservicesowner\",\"POSTGRES_PASSWORD\":\"password\"}"
  }
}

override_data {
  target = data.google_secret_manager_secret_version.keycloak_admin
  values = {
    secret_data = "{\"username\":\"admin\",\"password\":\"password\"}"
  }
}

run "gke_cluster_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.gke_cluster) >= 1 && length(local.naming.gke_cluster) <= 40
    error_message = "GKE cluster name must be 1-40 chars"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.gke_cluster))
    error_message = "GKE cluster name must start with a letter, end alphanumeric, and contain lowercase letters, numbers, or hyphens"
  }
}

run "artifact_registry_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.artifact_registry) >= 2 && length(local.naming.artifact_registry) <= 63
    error_message = "Artifact Registry repository id must be 2-63 chars"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.artifact_registry))
    error_message = "Artifact Registry repository id must start with a letter, end alphanumeric, and contain lowercase letters, numbers, or hyphens"
  }
}

run "gke_node_pool_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.gke_node_pool) >= 1 && length(local.naming.gke_node_pool) <= 40
    error_message = "GKE node pool name must be 1-40 chars"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.gke_node_pool))
    error_message = "GKE node pool name must start with a letter, end alphanumeric, and contain lowercase letters, numbers, or hyphens"
  }
}

run "cloud_sql_instance_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.cloud_sql_instance) >= 1 && length(local.naming.cloud_sql_instance) <= 98
    error_message = "Cloud SQL instance name must be 1-98 chars"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.cloud_sql_instance))
    error_message = "Cloud SQL instance name must start with a letter, end alphanumeric, and contain lowercase letters, numbers, or hyphens"
  }
}

run "kms_key_ring_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.artifact_kms_ring) >= 1 && length(local.naming.artifact_kms_ring) <= 63
    error_message = "Cloud KMS key ring name must be 1-63 chars"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", local.naming.artifact_kms_ring))
    error_message = "Cloud KMS key ring name must contain only letters, numbers, underscores, or hyphens"
  }
}

run "kms_crypto_key_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.artifact_kms_key) >= 1 && length(local.naming.artifact_kms_key) <= 63
    error_message = "Cloud KMS crypto key name must be 1-63 chars"
  }

  assert {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", local.naming.artifact_kms_key))
    error_message = "Cloud KMS crypto key name must contain only letters, numbers, underscores, or hyphens"
  }
}

run "service_account_ids" {
  command = plan

  assert {
    condition = alltrue([
      for name in [
        local.naming.gke_nodes_sa,
        local.naming.external_secrets_sa,
        local.naming.gitlab_ci_sa,
      ] : length(name) >= 6 && length(name) <= 30
    ])
    error_message = "GCP service account account_id values must be 6-30 chars"
  }

  assert {
    condition = alltrue([
      for name in [
        local.naming.gke_nodes_sa,
        local.naming.external_secrets_sa,
        local.naming.gitlab_ci_sa,
      ] : can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", name))
    ])
    error_message = "GCP service account account_id values must start with a letter, end alphanumeric, and contain lowercase letters, numbers, or hyphens"
  }
}

run "cloud_run_keycloak_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.cloud_run_keycloak) >= 1 && length(local.naming.cloud_run_keycloak) <= 49
    error_message = "Cloud Run service name must be 1-49 chars"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.cloud_run_keycloak))
    error_message = "Cloud Run service name must start with a letter, end alphanumeric, and contain lowercase letters, numbers, or hyphens"
  }
}

run "workload_identity_pool_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.gitlab_pool) >= 4 && length(local.naming.gitlab_pool) <= 32
    error_message = "Workload identity pool id must be 4-32 chars"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.gitlab_pool))
    error_message = "Workload identity pool id must start with a letter, end alphanumeric, and contain lowercase letters, numbers, or hyphens"
  }
}
