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

  name                = local.identity_name[each.key]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "addon" {
  for_each = local.azure_workload_identities

  name                      = each.value.name
  user_assigned_identity_id = azurerm_user_assigned_identity.addon[each.key].id
  issuer                    = azurerm_kubernetes_cluster.this.oidc_issuer_url
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = each.value.subject
}

resource "azurerm_role_assignment" "external_secrets_key_vault" {
  principal_id         = azurerm_user_assigned_identity.addon["external_secrets"].principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.platform.id
}

resource "azurerm_user_assigned_identity" "gitlab_ci" {
  count = var.gitlab_project_path == "" ? 0 : 1

  name                = local.identity_name.gitlab_ci
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "gitlab_ci" {
  count = var.gitlab_project_path == "" ? 0 : 1

  name                      = "gitlab-${var.environment}"
  user_assigned_identity_id = azurerm_user_assigned_identity.gitlab_ci[0].id
  issuer                    = "https://gitlab.com"
  audience                  = ["https://gitlab.com"]
  subject                   = "project_path:${var.gitlab_project_path}:ref_type:branch:ref:${var.gitlab_ref}"
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

# Dedicated CI identity for GitHub Actions app-repo pipelines (image build/push
# to ACR only -- these repos don't run Terraform, so unlike gitlab_ci this
# gets no resource-group Contributor grant, just AcrPush).
resource "azurerm_user_assigned_identity" "github_ci" {
  count = length(var.github_repos) == 0 ? 0 : 1

  name                = local.identity_name.github_ci
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "github_ci" {
  for_each = toset(var.github_repos)

  name                      = "github-${replace(each.value, "/", "-")}"
  user_assigned_identity_id = azurerm_user_assigned_identity.github_ci[0].id
  issuer                    = "https://token.actions.githubusercontent.com"
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "repo:${each.value}:ref:${var.github_ref}"
}

resource "azurerm_role_assignment" "github_ci_acr_push" {
  count = length(var.github_repos) == 0 ? 0 : 1

  principal_id         = azurerm_user_assigned_identity.github_ci[0].principal_id
  role_definition_name = "AcrPush"
  scope                = azurerm_container_registry.this.id
}
