locals {
  gcp_workload_identities = {
    external_secrets = {
      account_id = "eso-${var.environment}"
      namespace  = "external-secrets"
      ksa_name   = "external-secrets"
    }
  }
}

resource "google_service_account" "gke_nodes" {
  account_id   = "gke-${var.project_name}${var.environment}-sa"
  display_name = "GKE node service account for ${var.project_name}-${var.environment}"
}

resource "google_artifact_registry_repository_iam_member" "gke_nodes_repository_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_connect" {
  project = var.project_id
  role    = "roles/container.connect"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "service_account_connect" {
  count   = var.service_account_email != "" ? 1 : 0
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${var.service_account_email}"
}

resource "google_service_account" "addon" {
  for_each = local.gcp_workload_identities

  account_id   = each.value.account_id
  display_name = "${each.value.ksa_name} workload identity for ${local.cluster_name}"
}

resource "google_service_account_iam_member" "addon_workload_identity_user" {
  for_each = local.gcp_workload_identities

  service_account_id = google_service_account.addon[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.workload_pool}[${each.value.namespace}/${each.value.ksa_name}]"
}

resource "google_iam_workload_identity_pool" "gitlab" {
  count = var.gitlab_project_path == "" ? 0 : 1

  workload_identity_pool_id = "gitlab-${var.environment}"
  display_name              = "GitLab ${var.environment}"
}

resource "google_iam_workload_identity_pool_provider" "gitlab" {
  count = var.gitlab_project_path == "" ? 0 : 1

  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "gitlab"
  display_name                       = "GitLab OIDC"

  attribute_mapping = {
    "google.subject"            = "assertion.sub"
    "attribute.project_path"    = "assertion.project_path"
    "attribute.ref"             = "assertion.ref"
    "attribute.ref_type"        = "assertion.ref_type"
    "attribute.pipeline_source" = "assertion.pipeline_source"
  }

  attribute_condition = "attribute.project_path == '${var.gitlab_project_path}' && attribute.ref == '${var.gitlab_ref}' && attribute.ref_type == 'branch'"

  oidc {
    issuer_uri = "https://gitlab.com"
  }
}

resource "google_service_account" "gitlab_ci" {
  count = var.gitlab_project_path == "" ? 0 : 1

  account_id   = "gitlab-ci-${var.environment}"
  display_name = "GitLab CI federated service account for ${local.cluster_name}"
}

resource "google_service_account_iam_member" "gitlab_ci_workload_identity_user" {
  count = var.gitlab_project_path == "" ? 0 : 1

  service_account_id = google_service_account.gitlab_ci[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab[0].name}/attribute.project_path/${var.gitlab_project_path}"
}

resource "google_project_iam_member" "gitlab_ci_roles" {
  for_each = var.gitlab_project_path == "" ? toset([]) : toset([
    "roles/artifactregistry.writer",
    "roles/container.developer",
    "roles/secretmanager.admin",
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gitlab_ci[0].email}"
}
