location     = "westeurope"
project_name = "microservices1691715"
environment  = "dev"
acr_sku_name = "Basic"
aks_vm_size  = "Standard_A2_v2"

# NGINX Ingress Controller configuration
nginx_ingress_version       = "4.7.1"
nginx_ingress_namespace     = "ingress-nginx"
nginx_ingress_replica_count = 1  # Using 1 replica for dev environment to save resources
