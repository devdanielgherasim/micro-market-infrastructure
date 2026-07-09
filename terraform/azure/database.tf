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
  name                = substr("pg-${replace(var.project_name, "-", "")}-${var.environment}-${random_id.postgresql_suffix.hex}", 0, 63)
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
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = true

  tags = local.tags
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.postgresql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "microservices" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgresql.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

