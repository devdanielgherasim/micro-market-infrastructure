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
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.27"
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

provider "postgresql" {
  host            = azurerm_postgresql_flexible_server.postgresql.fqdn
  port            = 5432
  database        = var.database_name
  username        = local.db_admin_username
  password        = random_password.postgresql_owner.result
  sslmode         = "require"
  superuser       = false
  connect_timeout = 15
}
