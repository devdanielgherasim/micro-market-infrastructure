terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"   # Or your required version
    }
  }
}

provider "azurerm" {
  features {}  # <-- THIS IS MANDATORY

  use_oidc        = true
  client_id       = var.client_id
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
