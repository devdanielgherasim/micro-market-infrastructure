location                   = "westeurope"
project_name               = "microservices1691715"
environment                = "dev"
acr_sku_name               = "Basic"
aks_vm_size                = "Standard_A2_v2"
create_acr_role_assignment = true
kubernetes_version         = "1.32.4"
# Resource tags
tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Project     = "Microservices"
  Owner       = "DevOps"
  CostCenter  = "IT-123"
}

# NGINX Ingress Controller configuration
nginx_ingress_version       = "4.7.1"
nginx_ingress_namespace     = "ingress-nginx"
nginx_ingress_replica_count = 1 # Using 1 replica for dev environment to save resources

# ArgoCD configuration
argocd_version       = "5.46.7"
argocd_namespace     = "argocd"
argocd_replica_count = 1 # Using 1 replica for dev environment to save resources

# cert-manager configuration
cert_manager_version       = "v1.13.2"
cert_manager_namespace     = "cert-manager"
cert_manager_replica_count = 1 # Using 1 replica for dev environment to save resources

# Prometheus configuration
prometheus_version       = "25.8.0"
prometheus_namespace     = "monitoring"
prometheus_replica_count = 1 # Using 1 replica for dev environment to save resources

# Grafana configuration
grafana_version       = "7.0.11"
grafana_namespace     = "monitoring"
grafana_replica_count = 1 # Using 1 replica for dev environment to save resources

# Certificate configuration
cert_manager_email       = "devops@microservices1691715.com" # Use a realistic email address
cert_manager_issuer_type = "staging"                         # Use staging for dev environment to avoid rate limits
enable_tls               = true

# DNS configuration
dns_zone_name   = "dev.microservices1691715.com" # Use a subdomain for dev environment
create_dns_zone = true
