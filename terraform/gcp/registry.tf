resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = local.artifact_registry_name
  description   = "Docker repository for ${var.project_name} in ${var.environment}"
  format        = "DOCKER"

  # Customer-managed encryption key (see kms.tf) rather than the Google-managed
  # default (checkov CKV_GCP_84).
  kms_key_name = google_kms_crypto_key.artifact_registry.id

  depends_on = [google_kms_crypto_key_iam_member.artifact_registry]
}
