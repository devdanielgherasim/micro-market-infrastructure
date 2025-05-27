# Kubernetes Module - main.tf
# This module creates an Azure Kubernetes Service (AKS) cluster

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = var.default_node_pool_name
    node_count          = var.node_count
    vm_size             = var.vm_size
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_count : null
    max_count           = var.enable_auto_scaling ? var.max_count : null
    os_disk_size_gb     = var.os_disk_size_gb
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

