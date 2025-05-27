# Main Terraform configuration for Azure resources
# This project provisions Azure infrastructure: Resource Group, ACR, AKS, Role Assignment, DNS Zone

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_container_registry" "this" {
  name                = "acr${var.project_name}${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.acr_sku_name
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "k8s-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "k8s-${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "rg-${var.project_name}-${var.environment}-aks"
  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.aks_vm_size
    os_disk_size_gb = 30
    # node_public_ip_enabled      = true
    node_public_ip_prefix_id    = azurerm_public_ip.this.public_ip_prefix_id
    temporary_name_for_rotation = "tempnode"
  }

  identity {
    type = "SystemAssigned"
  }
  tags       = var.tags
  depends_on = [azurerm_container_registry.this]
}

resource "azurerm_public_ip" "this" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "public-ip-${var.project_name}-${var.environment}-aks"
  resource_group_name = azurerm_resource_group.this.name
  domain_name_label   = var.project_name
}

resource "azurerm_role_assignment" "this" {
  principal_id                     = azurerm_kubernetes_cluster.this.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.this.id
  skip_service_principal_aad_check = true
}

# module "dns" {
#   source                = "../modules/dns"
#   count                 = var.create_dns_zone ? 1 : 0
#   create_resource_group = true
#   resource_group_name   = "dnszone-${var.project_name}-${var.environment}"
#   location              = var.location
#   zone_name             = var.dns_zone_name
#   a_records = {
#     argocd = {
#       ttl     = 300
#       records = ["192.0.2.1"]
#     },
#     grafana = {
#       ttl     = 300
#       records = ["192.0.2.1"]
#     }
#   }
#   tags = local.tags
# }

locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}
