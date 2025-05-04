module "acr" {
  source              = "../../../modules/azure/container-registry"
  name                = "${var.resource_group_name}acr${var.environment}${substr(md5(var.client_id), 0, 6)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  admin_enabled       = true
}
