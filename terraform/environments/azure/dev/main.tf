module "rg" {
  source              = "../../../modules/azure/container-registry"
  name                = var.resource_group_name
  resource_group_name = var.resource_group_name
  location            = var.location
}

module "acr" {
  source              = "../../../modules/azure/container-registry"
  name                = var.acr_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  admin_enabled       = true
}
