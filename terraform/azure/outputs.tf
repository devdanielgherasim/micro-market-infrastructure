output "kubernetes_host" {
  value     = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive = true
}

output "kubernetes_client_certificate" {
  value     = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive = true
}

output "kubernetes_client_key" {
  value     = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive = true
}

output "kubernetes_cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "key_vault_name" {
  value       = azurerm_key_vault.platform.name
  description = "Azure Key Vault containing platform and application secrets"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.platform.vault_uri
  description = "Azure Key Vault URI containing platform and application secrets"
}

output "postgresql_host" {
  description = "Managed PostgreSQL endpoint used by application and Keycloak secrets"
  value       = azurerm_postgresql_flexible_server.postgresql.fqdn
}

output "postgresql_database" {
  description = "Managed PostgreSQL database name"
  value       = azurerm_postgresql_flexible_server_database.microservices.name
}

output "argocd_oidc_client_secret" {
  description = "Argo CD OIDC client secret seeded into cloud secret managers"
  value       = random_password.argocd_client.result
  sensitive   = true
}

output "argocd_admin_password" {
  description = "ArgoCD admin password stored in Key Vault under argocd-admin"
  value       = random_password.argocd_admin.result
  sensitive   = true
}

output "argocd_redis_password" {
  description = "ArgoCD Redis password stored in Key Vault under argocd-redis"
  value       = random_password.argocd_redis.result
  sensitive   = true
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = azurerm_container_registry.this.login_server
}

output "aks_oidc_issuer_url" {
  description = "AKS OIDC issuer URL used by workload identity"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "external_secrets_client_id" {
  description = "Azure workload identity client ID for External Secrets Operator"
  value       = azurerm_user_assigned_identity.addon["external_secrets"].client_id
}

output "gitlab_ci_client_id" {
  description = "Azure workload identity client ID for GitLab CI, when enabled"
  value       = try(azurerm_user_assigned_identity.gitlab_ci[0].client_id, null)
}

output "github_ci_client_id" {
  description = "Azure workload identity client ID for GitHub Actions CI, when enabled"
  value       = try(azurerm_user_assigned_identity.github_ci[0].client_id, null)
}

output "keycloak_default_hostname" {
  description = "Container Apps default FQDN for Keycloak, used as the keycloak-dns DNSEndpoint's CNAME target until the custom domain is bound. Uses the stable per-app ingress FQDN, not latest_revision_fqdn - the latter is revision-scoped and changes on every new revision (e.g. every apply that touches the container spec), which was silently breaking the DNS CNAME on redeploy."
  value       = azurerm_container_app.keycloak.ingress[0].fqdn
}

output "keycloak_custom_domain_verification_id" {
  description = "Value for the required asuid.auth.danielgherasim.com TXT record, needed before keycloak_custom_domain_enabled can be set to true"
  value       = azurerm_container_app.keycloak.custom_domain_verification_id
  sensitive   = true
}
