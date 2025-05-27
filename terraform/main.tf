# Main Terraform configuration file
# This file defines the root module that uses the child modules

# Resource Group for main resources
module "resource_group" {
  source = "./modules/resource_group"

  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# Azure Container Registry
module "container_registry" {
  source = "./modules/container_registry"

  name                = "acr${var.project_name}${var.environment}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku_name
  admin_enabled       = true
  tags                = local.tags
}

# Azure Kubernetes Service
module "kubernetes" {
  source = "./modules/kubernetes"

  name                = "k8s-${var.project_name}-${var.environment}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  dns_prefix          = "k8s-${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool_name = "default"
  node_count             = var.environment == "prod" ? 2 : 1
  vm_size                = var.aks_vm_size
  enable_auto_scaling    = var.environment == "prod" ? true : false
  min_count              = var.environment == "prod" ? 2 : null
  max_count              = var.environment == "prod" ? 5 : null
  os_disk_size_gb        = 30

  tags = local.tags
}

# Role assignment for AKS to pull images from ACR
module "acr_role_assignment" {
  source = "./modules/role_assignment"
  count  = var.create_acr_role_assignment ? 1 : 0

  principal_id                     = module.kubernetes.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = module.container_registry.id
  skip_service_principal_aad_check = true
}

# DNS Zone and records
module "dns" {
  source = "./modules/dns"
  count  = var.create_dns_zone ? 1 : 0

  create_resource_group = true
  resource_group_name   = "dnszone-${var.project_name}-${var.environment}"
  location              = var.location
  zone_name             = var.dns_zone_name

  a_records = {
    argocd = {
      ttl     = 300
      records = ["192.0.2.1"]  # Placeholder IP, will be updated by external-dns or manually
    },
    grafana = {
      ttl     = 300
      records = ["192.0.2.1"]  # Placeholder IP, will be updated by external-dns or manually
    }
  }

  tags = local.tags
}

# Kubernetes Addons (NGINX Ingress, Cert Manager, ArgoCD, Prometheus, Grafana)
module "kubernetes_addons" {
  source = "./modules/kubernetes_addons"
  count  = var.create_kubernetes_resources ? 1 : 0

  # General
  dns_zone_name = var.dns_zone_name
  enable_tls    = var.enable_tls

  # NGINX Ingress Controller
  install_nginx_ingress      = true
  nginx_ingress_version      = var.nginx_ingress_version
  nginx_ingress_namespace    = var.nginx_ingress_namespace
  nginx_ingress_replica_count = var.nginx_ingress_replica_count

  # Cert Manager
  install_cert_manager       = true
  cert_manager_version       = var.cert_manager_version
  cert_manager_namespace     = var.cert_manager_namespace
  cert_manager_replica_count = var.cert_manager_replica_count
  create_cluster_issuer      = true
  cert_manager_issuer_type   = var.cert_manager_issuer_type
  cert_manager_email         = var.cert_manager_email

  # ArgoCD
  install_argocd       = true
  argocd_version       = var.argocd_version
  argocd_namespace     = var.argocd_namespace
  argocd_replica_count = var.argocd_replica_count

  # Prometheus
  install_prometheus       = true
  prometheus_version       = var.prometheus_version
  prometheus_namespace     = var.prometheus_namespace
  prometheus_replica_count = var.prometheus_replica_count

  # Grafana
  install_grafana       = true
  grafana_version       = var.grafana_version
  grafana_namespace     = var.grafana_namespace
  grafana_replica_count = var.grafana_replica_count

  depends_on = [
    module.kubernetes
  ]
}

# Define local values
locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}
