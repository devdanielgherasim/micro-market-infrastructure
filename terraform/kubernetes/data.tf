data "terraform_remote_state" "azure" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-infrastructure"
    storage_account_name = "terraformmicrostate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}