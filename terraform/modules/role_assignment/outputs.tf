# Role Assignment Module - outputs.tf
# This file defines the outputs from the role assignment module

output "id" {
  description = "The ID of the role assignment"
  value       = azurerm_role_assignment.this.id
}

output "principal_id" {
  description = "The ID of the principal to which the role was assigned"
  value       = azurerm_role_assignment.this.principal_id
}

output "role_definition_name" {
  description = "The name of the role that was assigned"
  value       = azurerm_role_assignment.this.role_definition_name
}

output "scope" {
  description = "The scope at which the role was assigned"
  value       = azurerm_role_assignment.this.scope
}