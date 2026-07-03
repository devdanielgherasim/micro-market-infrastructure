terraform {
  required_version = ">= 1.10.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "=6.37.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "gcs" {
    bucket = "terraformmicroservicesstate"
    prefix = "terraform/environments/dev/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

locals {
  cluster_name           = "gke-${var.project_name}-${var.environment}"
  artifact_registry_name = "${var.project_name}-${var.environment}"
  workload_pool          = "${var.project_id}.svc.id.goog"
  common_labels = merge(var.labels, {
    environment = var.environment
    project     = var.project_name
    managed-by  = "terraform"
  })
}
