# DNS Module - main.tf
# This module creates an Azure DNS Zone and DNS records

resource "azurerm_resource_group" "dns" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_dns_zone" "this" {
  name                = var.zone_name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.dns[0].name : var.resource_group_name
  tags                = var.tags
}

# Create A records for services
resource "azurerm_dns_a_record" "records" {
  for_each            = var.a_records
  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.create_resource_group ? azurerm_resource_group.dns[0].name : var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records != null ? each.value.records : null
  target_resource_id  = each.value.target_resource_id != null ? each.value.target_resource_id : null
  tags                = var.tags
}
