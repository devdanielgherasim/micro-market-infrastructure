# Variables for Kubernetes Addons project
variable "create_kubernetes_resources" { type = bool }
variable "dns_zone_name" {}
variable "enable_tls" { type = bool }

# NGINX Ingress
variable "nginx_ingress_version" {}
variable "nginx_ingress_namespace" {}
variable "nginx_ingress_replica_count" {}

# Cert Manager
variable "cert_manager_version" {}
variable "cert_manager_namespace" {}
variable "cert_manager_replica_count" {}
variable "cert_manager_issuer_type" {}
variable "cert_manager_email" {}

# ArgoCD
variable "argocd_version" {}
variable "argocd_namespace" {}
variable "argocd_replica_count" {}

# Prometheus
variable "prometheus_version" {}
variable "prometheus_namespace" {}
variable "prometheus_replica_count" {}

# Grafana
variable "grafana_version" {}
variable "grafana_namespace" {}
variable "grafana_replica_count" {}

# You will need to add variables for kubeconfig and other Azure outputs, or use remote state/data sources.
