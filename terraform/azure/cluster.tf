resource "azurerm_kubernetes_cluster" "this" {
  name                = local.cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = local.cluster_name
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "rg-${var.project_name}-${var.environment}-aks"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Keep node/control-plane patch versions current automatically (checkov
  # CKV_AZURE_171) and enable the Azure Policy add-on for baseline
  # in-cluster policy enforcement (checkov CKV_AZURE_116).
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"
  azure_policy_enabled      = true

  # Fully public by default (matches historical behavior). Populate
  # var.api_allowed_cidrs to restrict the API server to known operator/CI
  # ranges; the block is only emitted when the list is non-empty so an
  # empty default can never be mistaken for a deny-all.
  dynamic "api_server_access_profile" {
    for_each = length(var.api_allowed_cidrs) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_allowed_cidrs
    }
  }

  default_node_pool {
    name                 = "default"
    min_count            = var.min_node_count
    max_count            = var.max_node_count
    node_count           = var.node_count
    vm_size              = var.aks_vm_size
    os_disk_size_gb      = 50
    auto_scaling_enabled = true

    upgrade_settings {
      max_surge = "10%"
    }

    tags = merge(var.tags, {
      NodePool = "default"
    })
  }

  identity {
    type = "SystemAssigned"
  }

  # node_count is managed by the cluster autoscaler at runtime; ignoring it
  # prevents Terraform from resetting the count on every apply.
  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  tags       = local.tags
  depends_on = [azurerm_container_registry.this]
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.this.id
  skip_service_principal_aad_check = true
}
