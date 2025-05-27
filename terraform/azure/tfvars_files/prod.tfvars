location     = "westeurope"
project_name = "microservices1691715"
environment  = "prod"
acr_sku_name = "Standard"  # Using Standard SKU for production for better performance
aks_vm_size  = "Standard_D2s_v3"  # Using a more powerful VM size for production
create_acr_role_assignment = true

# Resource tags
tags = {
  ManagedBy   = "Terraform"
  Environment = "Production"
  Project     = "Microservices"
  Owner       = "DevOps"
  CostCenter  = "IT-123"
}

# NGINX Ingress Controller configuration
nginx_ingress_version       = "4.7.1"
nginx_ingress_namespace     = "ingress-nginx"
nginx_ingress_replica_count = 2  # Using 2 replicas for prod environment for high availability

# ArgoCD configuration
argocd_version       = "5.46.7"
argocd_namespace     = "argocd"
argocd_replica_count = 2  # Using 2 replicas for prod environment for high availability

# cert-manager configuration
cert_manager_version       = "v1.13.2"
cert_manager_namespace     = "cert-manager"
cert_manager_replica_count = 2  # Using 2 replicas for prod environment for high availability

# Prometheus configuration
prometheus_version       = "25.8.0"
prometheus_namespace     = "monitoring"
prometheus_replica_count = 2  # Using 2 replicas for prod environment for high availability

# Grafana configuration
grafana_version       = "7.0.11"
grafana_namespace     = "monitoring"
grafana_replica_count = 2  # Using 2 replicas for prod environment for high availability

# Certificate configuration
cert_manager_email = "devops@microservices1691715.com"  # Use a realistic email address
cert_manager_issuer_type = "production"  # Use production for prod environment for valid certificates
enable_tls = true

# DNS configuration
dns_zone_name   = "microservices1691715.com"
create_dns_zone = true
