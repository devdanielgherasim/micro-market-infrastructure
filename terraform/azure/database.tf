locals {
  db_admin_username = "microservicesowner"
}

# A failed create in a disallowed region (germanywestcentral) left a stuck
# name reservation at the Azure ARM layer - invisible to `show`/`list` but
# still blocking a same-named create elsewhere. Azure's own error told us to
# pick a new name; a stable random suffix means this can't recur on a future
# region retry.
resource "random_id" "postgresql_suffix" {
  byte_length = 2
}

resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                = local.naming.postgresql_flexible_server
  resource_group_name = azurerm_resource_group.this.name
  location            = var.secondary_location

  version                = "16"
  administrator_login    = local.db_admin_username
  administrator_password = random_password.postgresql_owner.result

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  # Azure Postgres Flexible Server enforces a hard floor of 7 days (unlike
  # AWS RDS, which allows 1) - 7 for every environment, since going lower
  # isn't possible regardless of environment.
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  # Private access only: AKS and the Keycloak Container App reach PostgreSQL
  # through the peered/integrated VNets and the private DNS zone in network.tf.
  delegated_subnet_id           = azurerm_subnet.postgresql.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgresql.id
  public_network_access_enabled = false

  tags = local.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

resource "azurerm_postgresql_flexible_server_database" "microservices" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
