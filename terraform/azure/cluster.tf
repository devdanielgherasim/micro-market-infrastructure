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
  automatic_channel_upgrade = "patch"
  azure_policy_enabled      = true

  default_node_pool {
    name                 = "default"
    min_count            = var.min_node_count
    max_count            = var.max_node_count
    node_count           = var.node_count
    vm_size              = var.aks_vm_size
    os_disk_size_gb      = 50
    auto_scaling_enabled = true

    tags = merge(var.tags, {
      NodePool = "default"
    })
  }

  identity {
    type = "SystemAssigned"
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
