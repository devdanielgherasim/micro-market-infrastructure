module "acr" {
  source = "../../../modules/azure/container-registry"

  name                = "devacr01"
  resource_group_name = var.resource_group_name
  location            = var.location
  admin_enabled       = true
}
