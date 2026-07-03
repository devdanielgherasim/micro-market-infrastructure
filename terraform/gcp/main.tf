terraform {
  required_version = ">= 1.10.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "=6.37.0"
    }
  }

  backend "gcs" {
    bucket = "terraformmicroservicesstate"
    prefix = "terraform/environments/dev/state"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = var.credentials_file
}

resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = "${var.project_name}-${var.environment}"
  description   = "Docker repository for ${var.project_name} in ${var.environment}"
  format        = "DOCKER"
}


resource "google_container_cluster" "this" {
  name                     = "gke-${var.project_name}-${var.environment}"
  location                 = var.zone
  project                  = var.project_id
  deletion_protection      = var.deletion_protection
  remove_default_node_pool = true
  initial_node_count       = var.node_count

  networking_mode = "VPC_NATIVE"

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }
  node_config {
    disk_type = "pd-standard"
  }
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  resource_labels    = var.labels
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.this.name
  location   = var.zone
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type

    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type

    labels = var.labels
    tags   = ["gke-node", "${var.project_name}-${var.environment}"]
  }


  management {
    auto_repair  = var.auto_repair
    auto_upgrade = var.auto_upgrade
  }
}

resource "google_service_account" "gke_sa" {
  account_id   = "gke-${var.project_name}${var.environment}-sa"
  display_name = "GKE Service Account for ${var.project_name}-${var.environment}"
}

resource "google_artifact_registry_repository_iam_member" "gke_sa_repository_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "gke_sa_connect" {
  project = var.project_id
  role    = "roles/container.connect"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "service_account_connect" {
  count   = var.service_account_email != "" ? 1 : 0
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${var.service_account_email}"
}

resource "google_secret_manager_secret" "certificate_secret" {
  secret_id = "${var.project_name}-${var.environment}-certificate"

  replication {
    automatic = true
  }

  labels = var.labels
}

resource "google_secret_manager_secret_iam_binding" "certificate_secret_binding" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.certificate_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${google_service_account.gke_sa.email}"
  ]
}
