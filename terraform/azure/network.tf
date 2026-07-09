resource "azurerm_resource_group" "this" {
  name     = local.naming.resource_group
  location = var.location
  tags     = local.tags
}
