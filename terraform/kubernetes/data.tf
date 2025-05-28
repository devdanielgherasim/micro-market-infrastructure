data "terraform_remote_state" "azure" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-infrastructure"
    storage_account_name = "terraformmicrostate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

data "azurerm_public_ip" "aks_public_ip" {
  name                = "aks-lb-ip-${var.project_name}-${var.environment}"
  resource_group_name = "rg-${var.project_name}-${var.environment}"
}
