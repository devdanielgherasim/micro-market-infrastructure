# Role Assignment Module - main.tf
# This module creates an Azure Role Assignment

resource "azurerm_role_assignment" "this" {
  principal_id                     = var.principal_id
  role_definition_name             = var.role_definition_name
  scope                            = var.scope
  skip_service_principal_aad_check = var.skip_service_principal_aad_check
}