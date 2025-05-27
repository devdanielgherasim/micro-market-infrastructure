# Main Terraform configuration for Kubernetes Addons
# This project provisions Kubernetes resources (NGINX, Cert Manager, ArgoCD, Prometheus, Grafana)

module "kubernetes_addons" {
  source = "../modules/kubernetes_addons"
  count  = var.create_kubernetes_resources ? 1 : 0

  # General
  dns_zone_name = var.dns_zone_name
  enable_tls    = var.enable_tls

  # NGINX Ingress Controller
  install_nginx_ingress       = true
  nginx_ingress_version       = var.nginx_ingress_version
  nginx_ingress_namespace     = var.nginx_ingress_namespace
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

  # You will need to provide kubeconfig and other outputs from the Azure project
  # as input variables or via remote state/data sources.
}
