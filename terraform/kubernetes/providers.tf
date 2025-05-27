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
    # These values should be provided via environment variables or command line arguments
    resource_group_name  = "rg-infrastructure"
    storage_account_name = "terraformmicrostate"
    container_name       = "tfstate"
    key                  = "terraform-kubernetes.tfstate"
  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "kubernetes" {
  host = module.kubernetes.host

  client_certificate     = base64decode(module.kubernetes.client_certificate)
  client_key             = base64decode(module.kubernetes.client_key)
  cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)

  # This ensures the provider doesn't fail during plan phase
  # when the cluster doesn't exist yet
  dynamic "exec" {
    for_each = var.create_kubernetes_resources ? [] : [1]
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
    host = module.kubernetes.host

    client_certificate     = base64decode(module.kubernetes.client_certificate)
    client_key             = base64decode(module.kubernetes.client_key)
    cluster_ca_certificate = base64decode(module.kubernetes.cluster_ca_certificate)

    # This ensures the provider doesn't fail during plan phase
    # when the cluster doesn't exist yet
    dynamic "exec" {
      for_each = var.create_kubernetes_resources ? [] : [1]
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "echo"
        args        = ["{}"]
      }
    }
  }
}
