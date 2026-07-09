# GCP Secret Manager is the platform key and secret boundary for this phase.
# Secret payloads are managed in secrets.tf so External Secrets can consume them.

# Customer-managed key for Artifact Registry image encryption at rest
# (checkov CKV_GCP_84). Mirrors the AWS root's dedicated ECR KMS key
# (aws/kms.tf) for cross-cloud parity.
resource "google_kms_key_ring" "artifact_registry" {
  name     = "${local.cluster_name}-ar"
  location = var.region
}

resource "google_kms_crypto_key" "artifact_registry" {
  #checkov:skip=CKV_GCP_82: deliberately left destroyable (no lifecycle
  #  prevent_destroy / key-level deletion protection) - this environment is
  #  fully torn down at the end of every demo cycle (spin up -> demo ->
  #  destroy, see project plan), and a protected key would block
  #  `terraform destroy`. Mirrors the same tradeoff already made for the
  #  Azure Key Vault (purge_protection_enabled=false) and AWS Secrets
  #  Manager (recovery_window_in_days=0) in this repo.
  name     = "artifact-registry"
  key_ring = google_kms_key_ring.artifact_registry.id

  rotation_period = "7776000s" # 90 days
}

# Artifact Registry's Google-managed service agent needs encrypt/decrypt on
# the key before the repository can be created with it. (google_project_service_identity
# is GA as of provider ~4.35+; no google-beta provider required.)
resource "google_project_service_identity" "artifact_registry" {
  provider = google-beta

  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_kms_crypto_key_iam_member" "artifact_registry" {
  crypto_key_id = google_kms_crypto_key.artifact_registry.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.artifact_registry.email}"
}
