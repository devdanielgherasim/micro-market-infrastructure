# Single source of truth for Azure resource names in this Terraform root.
# Resource-specific limits are enforced in naming.tftest.hcl.
locals {
  cluster_name = "k8s-${var.project_name}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })

  # Short code for resource types with tight name budgets.
  short_project = "mmkt"

  naming = {
    resource_group = "rg-${var.project_name}-${var.environment}"
    aks            = local.cluster_name
    aks_node_rg    = "rg-${var.project_name}-${var.environment}-aks"

    acr = lower(replace("acr${var.project_name}${var.environment}", "-", ""))

    key_vault = substr("kv-${local.short_project}-${var.environment}", 0, 24)

    log_analytics_workspace    = "log-keycloak-${var.environment}"
    container_app_environment  = "keycloak-env-${var.environment}"
    container_app              = "keycloak-${var.environment}"
    container_app_managed_cert = "keycloak-cert-${var.environment}"
    postgresql_flexible_server = substr("pg-${local.short_project}-${var.environment}-${random_id.postgresql_suffix.hex}", 0, 63)
  }

  identity_name = merge(
    { for k, v in local.azure_workload_identities : k => "${local.cluster_name}-${v.name}" },
    {
      gitlab_ci = "${local.cluster_name}-gitlab-ci"
      github_ci = "${local.cluster_name}-github-ci"
    }
  )
}
