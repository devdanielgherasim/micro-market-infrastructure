resource "azurerm_resource_group" "this" {
  name     = local.naming.resource_group
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "aks" {
  name                = local.naming.aks_virtual_network
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.42.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = local.naming.aks_subnet
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.42.0.0/20"]
}

resource "azurerm_virtual_network" "postgresql" {
  name                = local.naming.postgresql_virtual_network
  location            = var.secondary_location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.43.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "postgresql" {
  name                 = local.naming.postgresql_subnet
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.postgresql.name
  address_prefixes     = ["10.43.0.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "postgresql-flexible-server"

    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "container_app_environment" {
  name                 = local.naming.container_app_subnet
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.postgresql.name
  address_prefixes     = ["10.43.8.0/21"]

  delegation {
    name = "container-app-environment"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_virtual_network_peering" "aks_to_postgresql" {
  name                      = local.naming.aks_to_postgresql_vnet_peering
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.aks.name
  remote_virtual_network_id = azurerm_virtual_network.postgresql.id
}

resource "azurerm_virtual_network_peering" "postgresql_to_aks" {
  name                      = local.naming.postgresql_to_aks_vnet_peering
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.postgresql.name
  remote_virtual_network_id = azurerm_virtual_network.aks.id
}

resource "azurerm_private_dns_zone" "postgresql" {
  name                = local.naming.postgresql_private_dns_zone
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_aks" {
  name                  = local.naming.postgresql_private_dns_link_aks
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.aks.id
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = local.naming.postgresql_private_dns_link_postgres
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = azurerm_virtual_network.postgresql.id
  tags                  = local.tags
}
