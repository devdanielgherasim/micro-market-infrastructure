# These resources are gated behind var.manage_postgresql_roles (default
# false) because the PostgreSQL Flexible Server is private-only and normal
# Terraform runners cannot reach it. They stay defined here for anyone who
# does have direct VNet/bastion access and wants Terraform-native drift
# detection, but the recommended, repeatable way to actually provision
# catalog_svc/orders_svc/audit_svc is the in-cluster ArgoCD Sync-hook Job at
# platform-gitops/platform/postgres-app-roles - AKS already has VNet peering
# + private DNS access to this server (see network.tf), so it needs no
# bastion. Do not run both paths against the same live server without
# reconciling state first - see var.manage_postgresql_roles's description.
locals {
  app_db_roles = {
    catalog = {
      username = "catalog_svc"
      password = random_password.catalog_db.result
      schema   = "catalog"
    }
    orders = {
      username = "orders_svc"
      password = random_password.orders_db.result
      schema   = "orders"
    }
    audit = {
      username = "audit_svc"
      password = random_password.audit_db.result
      schema   = "audit"
    }
  }

  managed_app_db_roles = var.manage_postgresql_roles ? local.app_db_roles : {}
}

resource "postgresql_role" "service" {
  for_each = local.managed_app_db_roles

  name     = each.value.username
  login    = true
  password = each.value.password
  search_path = [
    each.value.schema,
    "public",
  ]

  depends_on = [azurerm_postgresql_flexible_server_database.microservices]
}

resource "postgresql_schema" "service" {
  for_each = local.managed_app_db_roles

  database = var.database_name
  name     = each.value.schema
  owner    = postgresql_role.service[each.key].name

  policy {
    role   = postgresql_role.service[each.key].name
    usage  = true
    create = true
  }
}

resource "postgresql_grant" "database" {
  for_each = local.managed_app_db_roles

  database    = var.database_name
  role        = postgresql_role.service[each.key].name
  object_type = "database"
  privileges  = ["CONNECT", "TEMPORARY"]
}

resource "postgresql_grant" "schema" {
  for_each = local.managed_app_db_roles

  database    = var.database_name
  role        = postgresql_role.service[each.key].name
  schema      = postgresql_schema.service[each.key].name
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

resource "postgresql_grant" "tables" {
  for_each = local.managed_app_db_roles

  database    = var.database_name
  role        = postgresql_role.service[each.key].name
  schema      = postgresql_schema.service[each.key].name
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES", "TRIGGER"]
}

resource "postgresql_grant" "sequences" {
  for_each = local.managed_app_db_roles

  database    = var.database_name
  role        = postgresql_role.service[each.key].name
  schema      = postgresql_schema.service[each.key].name
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]
}

resource "postgresql_default_privileges" "tables" {
  for_each = local.managed_app_db_roles

  database    = var.database_name
  role        = postgresql_role.service[each.key].name
  owner       = local.db_admin_username
  schema      = postgresql_schema.service[each.key].name
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE", "TRUNCATE", "REFERENCES", "TRIGGER"]
}

resource "postgresql_default_privileges" "sequences" {
  for_each = local.managed_app_db_roles

  database    = var.database_name
  role        = postgresql_role.service[each.key].name
  owner       = local.db_admin_username
  schema      = postgresql_schema.service[each.key].name
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]
}
