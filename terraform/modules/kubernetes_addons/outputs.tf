# Kubernetes Addons Module - outputs.tf
# This file defines the outputs from the kubernetes_addons module

# NGINX Ingress Controller outputs
output "nginx_ingress_status" {
  description = "The status of the NGINX Ingress Controller deployment"
  value       = var.install_nginx_ingress ? "Installed" : "Skipped"
}

output "nginx_ingress_namespace" {
  description = "The namespace where the NGINX Ingress Controller is installed"
  value       = var.install_nginx_ingress ? var.nginx_ingress_namespace : null
}

# Cert Manager outputs
output "cert_manager_status" {
  description = "The status of the cert-manager deployment"
  value       = var.install_cert_manager ? "Installed" : "Skipped"
}

output "cert_manager_namespace" {
  description = "The namespace where cert-manager is installed"
  value       = var.install_cert_manager ? var.cert_manager_namespace : null
}

output "cluster_issuer_name" {
  description = "The name of the ClusterIssuer created for Let's Encrypt"
  value       = var.install_cert_manager && var.create_cluster_issuer ? "${var.cert_manager_issuer_type}-letsencrypt" : null
}

# ArgoCD outputs
output "argocd_status" {
  description = "The status of the ArgoCD deployment"
  value       = var.install_argocd ? "Installed" : "Skipped"
}

output "argocd_namespace" {
  description = "The namespace where ArgoCD is installed"
  value       = var.install_argocd ? var.argocd_namespace : null
}

output "argocd_url" {
  description = "The URL to access ArgoCD"
  value       = var.install_argocd && var.dns_zone_name != "" ? "https://argocd.${var.dns_zone_name}" : null
}

# Prometheus outputs
output "prometheus_status" {
  description = "The status of the Prometheus deployment"
  value       = var.install_prometheus ? "Installed" : "Skipped"
}

output "prometheus_namespace" {
  description = "The namespace where Prometheus is installed"
  value       = var.install_prometheus ? var.prometheus_namespace : null
}

# Grafana outputs
output "grafana_status" {
  description = "The status of the Grafana deployment"
  value       = var.install_grafana ? "Installed" : "Skipped"
}

output "grafana_namespace" {
  description = "The namespace where Grafana is installed"
  value       = var.install_grafana ? var.grafana_namespace : null
}

output "grafana_url" {
  description = "The URL to access Grafana"
  value       = var.install_grafana && var.dns_zone_name != "" ? "https://grafana.${var.dns_zone_name}" : null
}