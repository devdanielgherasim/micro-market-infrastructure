locals {
  azure_workload_identities = {
    external_secrets = {
      name      = "external-secrets"
      namespace = "external-secrets"
      subject   = "system:serviceaccount:external-secrets:external-secrets"
    }
  }
}

resource "azurerm_user_assigned_identity" "addon" {
  for_each = local.azure_workload_identities

  name                = "${local.cluster_name}-${each.value.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "addon" {
  for_each = local.azure_workload_identities

  name                = each.value.name
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.addon[each.key].id
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  audience            = ["api://AzureADTokenExchange"]
  subject             = each.value.subject
}

resource "azurerm_role_assignment" "external_secrets_key_vault" {
  principal_id         = azurerm_user_assigned_identity.addon["external_secrets"].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.platform.id
}

resource "azurerm_user_assigned_identity" "gitlab_ci" {
  count = var.gitlab_project_path == "" ? 0 : 1

  name                = "${local.cluster_name}-gitlab-ci"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "gitlab_ci" {
  count = var.gitlab_project_path == "" ? 0 : 1

  name                = "gitlab-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  parent_id           = azurerm_user_assigned_identity.gitlab_ci[0].id
  issuer              = "https://gitlab.com"
  audience            = ["https://gitlab.com"]
  subject             = "project_path:${var.gitlab_project_path}:ref_type:branch:ref:${var.gitlab_ref}"
}

resource "azurerm_role_assignment" "gitlab_ci_contributor" {
  count = var.gitlab_project_path == "" ? 0 : 1

  principal_id         = azurerm_user_assigned_identity.gitlab_ci[0].principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.this.id
}

resource "azurerm_role_assignment" "gitlab_ci_acr_push" {
  count = var.gitlab_project_path == "" ? 0 : 1

  principal_id         = azurerm_user_assigned_identity.gitlab_ci[0].principal_id
  role_definition_name = "AcrPush"
  scope                = azurerm_container_registry.this.id
}
