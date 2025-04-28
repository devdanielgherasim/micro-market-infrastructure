terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "terraformstatesa"
    container_name       = "tfstate"
    key                  = "azure/dev/terraform.tfstate"
  }
}
