resource "azurerm_container_registry" "this" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.acr_sku_name
  admin_enabled       = false
  tags                = local.tags
}
