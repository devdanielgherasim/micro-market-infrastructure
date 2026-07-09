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

output "secret_prefix" {
  value       = "${var.project_name}-${var.environment}"
  description = "GCP Secret Manager prefix containing platform and application secrets"
}

output "postgresql_host" {
  description = "Managed PostgreSQL public IP used by application and Keycloak secrets"
  value       = google_sql_database_instance.postgresql.public_ip_address
}

output "postgresql_database" {
  description = "Managed PostgreSQL database name"
  value       = google_sql_database.microservices.name
}

output "gke_service_account_email" {
  value       = google_service_account.gke_nodes.email
  description = "GKE node service account email"
}

output "argocd_oidc_client_secret" {
  value       = random_password.argocd_client.result
  description = "Argo CD OIDC client secret seeded into cloud secret managers"
  sensitive   = true
}

output "argocd_admin_password" {
  description = "ArgoCD admin password stored in Secret Manager under argocd-admin"
  value       = random_password.argocd_admin.result
  sensitive   = true
}

output "argocd_redis_password" {
  description = "ArgoCD Redis password stored in Secret Manager under argocd-redis"
  value       = random_password.argocd_redis.result
  sensitive   = true
}

output "artifact_registry_repository" {
  value       = google_artifact_registry_repository.this.name
  description = "Artifact Registry repository name"
}

output "workload_identity_pool" {
  value       = local.workload_pool
  description = "GKE Workload Identity pool"
}

output "external_secrets_service_account_email" {
  value       = google_service_account.addon["external_secrets"].email
  description = "Google service account bound to the External Secrets Kubernetes service account"
}

output "gitlab_ci_service_account_email" {
  value       = try(google_service_account.gitlab_ci[0].email, null)
  description = "Google service account for GitLab CI, when enabled"
}

output "gitlab_workload_identity_provider" {
  value       = try(google_iam_workload_identity_pool_provider.gitlab[0].name, null)
  description = "GCP Workload Identity Federation provider resource name for GitLab CI, when enabled"
}

output "keycloak_cloud_run_url" {
  value       = google_cloud_run_v2_service.keycloak.uri
  description = "Cloud Run default URL for Keycloak"
}

output "keycloak_domain_mapping_resource_records" {
  value       = google_cloud_run_domain_mapping.keycloak.status
  description = "DNS resource records to publish via the keycloak-dns DNSEndpoint for the Cloud Run domain mapping to validate"
}
