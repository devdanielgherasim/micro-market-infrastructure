terraform {
  # required_version = "=1.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.32.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-infrastructure"
    storage_account_name = "terraformmicrostate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}
