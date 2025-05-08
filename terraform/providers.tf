terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }

  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/68748909/terraform/state/default"
    lock_address   = "https://gitlab.com/api/v4/projects/68748909/terraform/state/default/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/68748909/terraform/state/default/lock"
    username       = "adriangherasim1"
  }
}

provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "random" {

}
