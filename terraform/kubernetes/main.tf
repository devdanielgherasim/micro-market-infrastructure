terraform {
  required_version = "=1.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.30.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "=5.10.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "=2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=2.37.1"
    }
  }

  backend "gcs" {}
}

provider "azurerm" {
  features {}

  client_id       = var.cloud_provider == "azure" ? var.client_id : null
  client_secret   = var.cloud_provider == "azure" ? var.client_secret : null
  tenant_id       = var.cloud_provider == "azure" ? var.tenant_id : null
  subscription_id = var.cloud_provider == "azure" ? var.subscription_id : null
}

provider "google" {
  project     = var.cloud_provider == "gcp" ? var.gcp_project : null
  region      = var.cloud_provider == "gcp" ? var.gcp_region : null
  zone        = var.cloud_provider == "gcp" ? var.gcp_zone : null
  credentials = var.cloud_provider == "gcp" ? var.gcp_credentials : null
}

provider "kubernetes" {
  host = (
    var.cloud_provider == "azure" ? data.terraform_remote_state.azure[0].outputs.kubernetes_host : var.cloud_provider == "gcp" ? data.terraform_remote_state.gcp[0].outputs.kubernetes_host : null
  )

  client_certificate = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_certificate) : null
  client_key = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_key) : null

  dynamic "exec" {
    for_each = var.cloud_provider == "gcp" ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }

  cluster_ca_certificate = (
    var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_cluster_ca_certificate) : 
    var.cloud_provider == "gcp" ? base64decode(data.terraform_remote_state.gcp[0].outputs.kubernetes_cluster_ca_certificate) : null
  )
}

provider "helm" {
  kubernetes {
    host = (
      var.cloud_provider == "azure" ? data.terraform_remote_state.azure[0].outputs.kubernetes_host : var.cloud_provider == "gcp" ? data.terraform_remote_state.gcp[0].outputs.kubernetes_host : null
    )

    client_certificate = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_certificate) : null
    client_key = var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_client_key) : null

    dynamic "exec" {
      for_each = var.cloud_provider == "gcp" ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "gke-gcloud-auth-plugin"
      }
    }

    cluster_ca_certificate = (
      var.cloud_provider == "azure" ? base64decode(data.terraform_remote_state.azure[0].outputs.kubernetes_cluster_ca_certificate) : 
      var.cloud_provider == "gcp" ? base64decode(data.terraform_remote_state.gcp[0].outputs.kubernetes_cluster_ca_certificate) : null
    )
  }
}
