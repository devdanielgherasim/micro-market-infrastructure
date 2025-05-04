module "acr" {
  source              = "../../../modules/azure/container-registry"
  name                = "devacr01"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  admin_enabled       = true
}
