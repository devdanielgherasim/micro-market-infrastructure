# DNS Module - outputs.tf
# This file defines the outputs from the dns module

output "dns_zone_id" {
  description = "The ID of the DNS zone"
  value       = azurerm_dns_zone.this.id
}

output "dns_zone_name" {
  description = "The name of the DNS zone"
  value       = azurerm_dns_zone.this.name
}

output "dns_zone_name_servers" {
  description = "The name servers of the DNS zone"
  value       = azurerm_dns_zone.this.name_servers
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = var.create_resource_group ? azurerm_resource_group.dns[0].id : null
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.create_resource_group ? azurerm_resource_group.dns[0].name : var.resource_group_name
}

output "a_records" {
  description = "Map of A records created"
  value       = { for k, v in azurerm_dns_a_record.records : k => v.id }
}