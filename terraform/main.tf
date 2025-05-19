resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

resource "azurerm_container_registry" "acr" {

  name                = "acr${var.project_name}${var.environment}"
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
    vm_size    = var.aks_vm_size
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

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.nginx_ingress_version
  namespace        = var.nginx_ingress_namespace
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.replicaCount"
    value = var.nginx_ingress_replica_count
  }

  depends_on = [
    azurerm_kubernetes_cluster.k8s
  ]
}
