terraform {
  # Matches the >= 1.10.0 floor used by the aws/ and gcp/ Terraform roots
  # in this workspace (see infrastructure/terraform/{aws,gcp}/*.tf) so the
  # three cloud roots stay at parity instead of drifting independently.
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
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
}
