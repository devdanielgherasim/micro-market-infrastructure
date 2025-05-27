# Main Terraform configuration for Azure resources
# This project provisions Azure infrastructure: Resource Group, ACR, AKS, Role Assignment, DNS Zone

module "resource_group" {
  source   = "../modules/resource_group"
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.tags
}

module "container_registry" {
  source              = "../modules/container_registry"
  name                = "acr${var.project_name}${var.environment}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku_name
  admin_enabled       = true
  tags                = local.tags
}

module "kubernetes" {
  source                 = "../modules/kubernetes"
  name                   = "k8s-${var.project_name}-${var.environment}"
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  dns_prefix             = "k8s-${var.project_name}-${var.environment}"
  kubernetes_version     = var.kubernetes_version
  default_node_pool_name = "default"
  node_count             = var.environment == "prod" ? 2 : 1
  vm_size                = var.aks_vm_size
  enable_auto_scaling    = var.environment == "prod" ? true : false
  min_count              = var.environment == "prod" ? 2 : null
  max_count              = var.environment == "prod" ? 5 : null
  os_disk_size_gb        = 30
  tags                   = local.tags
}

module "acr_role_assignment" {
  source                           = "../modules/role_assignment"
  count                            = var.create_acr_role_assignment ? 1 : 0
  principal_id                     = module.kubernetes.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.container_registry.id
  skip_service_principal_aad_check = true
}

module "dns" {
  source                = "../modules/dns"
  count                 = var.create_dns_zone ? 1 : 0
  create_resource_group = true
  resource_group_name   = "dnszone-${var.project_name}-${var.environment}"
  location              = var.location
  zone_name             = var.dns_zone_name
  a_records = {
    argocd = {
      ttl     = 300
      records = ["192.0.2.1"]
    },
    grafana = {
      ttl     = 300
      records = ["192.0.2.1"]
    }
  }
  tags = local.tags
}

locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}
