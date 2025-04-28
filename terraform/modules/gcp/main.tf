resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = var.name
  description   = "GCP Artifact Docker Registry"
  format        = "DOCKER"
  labels = {
    environment = var.environment
  }
}

resource "google_project_iam_member" "writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.service_account_email}"
}
