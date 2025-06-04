locals {
  domain = {
    azure = "${var.project_name}.westeurope.cloudapp.azure.com"
    gcp   = data.terraform_remote_state.gcp[0].outputs.cluster_endpoint
  }

  current_domain = local.domain[var.cloud_provider]
}

data "terraform_remote_state" "azure" {
  count   = var.cloud_provider == "azure" ? 1 : 0
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-infrastructure"
    storage_account_name = "terraformmicrostate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

data "terraform_remote_state" "gcp" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  backend = "gcs"
  config = {
    bucket = "terraformmicroservicesstate"
    prefix = "terraform/state"
  }
}
