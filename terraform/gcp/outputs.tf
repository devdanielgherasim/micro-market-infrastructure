output "cluster_name" {
  value       = google_container_cluster.this.name
  description = "The name of the GKE cluster"
}

output "cluster_endpoint" {
  value       = google_container_cluster.this.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint
  description = "The endpoint for the GKE cluster"
  sensitive   = true
}

output "kubernetes_host" {
  value       = "https://${google_container_cluster.this.endpoint}"
  description = "The Kubernetes host"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = data.google_container_cluster.this.master_auth[0].cluster_ca_certificate
  description = "The CA certificate for the GKE cluster"
  sensitive   = true
}

output "kubernetes_cluster_ca_certificate" {
  value       = data.google_container_cluster.this.master_auth[0].cluster_ca_certificate
  description = "The CA certificate for the Kubernetes cluster"
  sensitive   = true
}

output "kubernetes_token" {
  value       = data.google_client_config.default.access_token
  description = "The token for Kubernetes authentication"
  sensitive   = true
}

output "project_id" {
  value       = var.project_id
  description = "The Google Cloud project ID"
}

output "zone" {
  value       = var.zone
  description = "The Google Cloud zone where resources are deployed"
}

output "node_pool_name" {
  value       = google_container_node_pool.primary_nodes.name
  description = "The name of the primary node pool"
}

output "node_count" {
  value       = var.node_count
  description = "The number of nodes in the primary node pool"
}

output "machine_type" {
  value       = var.machine_type
  description = "The machine type used for the nodes"
}

output "node_pool_version" {
  value       = google_container_node_pool.primary_nodes.version
  description = "The Kubernetes version of the node pool"
}

output "project_name" {
  value       = var.project_name
  description = "The name of the project"
}

output "domain_suffix" {
  value       = var.domain_suffix
  description = "The domain suffix used for DNS"
}
