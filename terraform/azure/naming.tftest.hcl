override_resource {
  target          = random_id.postgresql_suffix
  override_during = plan

  values = {
    hex = "abcd"
  }
}

run "resource_group_length" {
  command = plan

  assert {
    condition     = length(local.naming.resource_group) >= 1 && length(local.naming.resource_group) <= 90
    error_message = "resource_group name must be 1-90 chars for Microsoft.Resources/resourceGroups"
  }

  assert {
    condition     = !endswith(local.naming.resource_group, ".")
    error_message = "resource_group name must not end with a period"
  }
}

run "aks_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.aks) >= 1 && length(local.naming.aks) <= 63
    error_message = "aks name must be 1-63 chars for Microsoft.ContainerService/managedClusters"
  }

  assert {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*[A-Za-z0-9]$", local.naming.aks))
    error_message = "aks name must start/end alphanumeric and contain only alphanumerics, underscores, or hyphens"
  }
}

run "acr_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.acr) >= 5 && length(local.naming.acr) <= 50
    error_message = "acr name must be 5-50 chars for Microsoft.ContainerRegistry/registries"
  }

  assert {
    condition     = can(regex("^[a-z0-9]+$", local.naming.acr))
    error_message = "acr name must be alphanumerics only"
  }
}

run "key_vault_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.key_vault) >= 3 && length(local.naming.key_vault) <= 24
    error_message = "key_vault name must be 3-24 chars for Microsoft.KeyVault/vaults"
  }

  assert {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]*[A-Za-z0-9]$", local.naming.key_vault))
    error_message = "key_vault name must start with a letter, end alphanumeric, and contain only alphanumerics or hyphens"
  }

  assert {
    condition     = !can(regex("--", local.naming.key_vault))
    error_message = "key_vault name must not contain consecutive hyphens"
  }
}

run "log_analytics_workspace_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.log_analytics_workspace) >= 4 && length(local.naming.log_analytics_workspace) <= 63
    error_message = "log_analytics_workspace name must be 4-63 chars for Microsoft.OperationalInsights/workspaces"
  }

  assert {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]$", local.naming.log_analytics_workspace))
    error_message = "log_analytics_workspace name must start/end alphanumeric and contain only alphanumerics or hyphens"
  }
}

run "container_app_environment_length" {
  command = plan

  assert {
    condition     = length(local.naming.container_app_environment) >= 2 && length(local.naming.container_app_environment) <= 32
    error_message = "container_app_environment name must be 2-32 chars, using the Microsoft.App budget"
  }
}

run "container_app_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.container_app) >= 2 && length(local.naming.container_app) <= 32
    error_message = "container_app name must be 2-32 chars for Microsoft.App/containerApps"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.container_app))
    error_message = "container_app name must be lowercase, start with a letter, and end alphanumeric"
  }
}

run "container_app_managed_cert_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.container_app_managed_cert) >= 2 && length(local.naming.container_app_managed_cert) <= 32
    error_message = "container_app_managed_cert name must stay inside the Microsoft.App 2-32 char budget"
  }

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", local.naming.container_app_managed_cert))
    error_message = "container_app_managed_cert name must be lowercase, start with a letter, and end alphanumeric"
  }
}

run "postgresql_flexible_server_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.postgresql_flexible_server) >= 3 && length(local.naming.postgresql_flexible_server) <= 63
    error_message = "postgresql_flexible_server name must be 3-63 chars for Microsoft.DBforPostgreSQL/flexibleServers"
  }

  assert {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", local.naming.postgresql_flexible_server))
    error_message = "postgresql_flexible_server name must match ^[a-z0-9]+(-[a-z0-9]+)*$"
  }
}
