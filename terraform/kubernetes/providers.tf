terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0, < 4.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0, < 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0, < 3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0, < 1.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-infrastructure"
    storage_account_name = "terraformmicrostate"
    container_name       = "tfstate"
    key                  = "terraform-kubernetes.tfstate"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.azure.outputs.kubeconfig["host"]
  client_certificate     = base64decode(data.terraform_remote_state.azure.outputs.kubeconfig["client_certificate"])
  client_key             = base64decode(data.terraform_remote_state.azure.outputs.kubeconfig["client_key"])
  cluster_ca_certificate = base64decode(data.terraform_remote_state.azure.outputs.kubeconfig["cluster_ca_certificate"])

  # This ensures the provider doesn't fail during plan phase
  # when the cluster doesn't exist yet
  dynamic "exec" {
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "echo"
      args        = ["{}"]
    }
  }
}

# Helm provider
# This provider is configured to use the AKS cluster's credentials
provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.azure.outputs.kubeconfig["host"]
    client_certificate     = base64decode(data.terraform_remote_state.azure.outputs.kubeconfig["client_certificate"])
    client_key             = base64decode(data.terraform_remote_state.azure.outputs.kubeconfig["client_key"])
    cluster_ca_certificate = base64decode(data.terraform_remote_state.azure.outputs.kubeconfig["cluster_ca_certificate"])

    # This ensures the provider doesn't fail during plan phase
    # when the cluster doesn't exist yet
    dynamic "exec" {
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "echo"
        args        = ["{}"]
      }
    }
  }
}
