# Kubernetes Module - outputs.tf
# This file defines the outputs from the kubernetes module

output "id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description = "The kube config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "The raw kube config for the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "host" {
  description = "The Kubernetes cluster server host"
  value       = azurerm_kubernetes_cluster.this.kube_config.0.host
  sensitive   = true
}

output "client_certificate" {
  description = "The client certificate for authenticating to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config.0.client_certificate
  sensitive   = true
}

output "client_key" {
  description = "The client key for authenticating to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config.0.client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate for the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate
  sensitive   = true
}

output "identity" {
  description = "The identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.identity
}