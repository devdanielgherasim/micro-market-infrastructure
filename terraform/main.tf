resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

resource "random_string" "acr-random_string" {
  length  = 5
  special = false
}

resource "azurerm_container_registry" "acr" {

  name                = "acr${var.project_name}${var.environment}${random_string.acr-random_string.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.acr_sku_name
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "k8s-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "k8s-${var.project_name}-${var.environment}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_A2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_role_assignment" "ra_acr_k8s" {
  principal_id                     = azurerm_kubernetes_cluster.k8s.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
