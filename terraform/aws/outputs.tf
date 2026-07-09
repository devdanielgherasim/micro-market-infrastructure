output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.this.endpoint
  sensitive   = true
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by application name"
  value = {
    for name, repository in aws_ecr_repository.application :
    name => repository.repository_url
  }
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}"
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller IRSA"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator IRSA"
  value       = aws_iam_role.external_secrets.arn
}

output "secret_prefix" {
  description = "AWS Secrets Manager prefix containing platform and application secrets"
  value       = local.secret_prefix
}

output "postgresql_host" {
  description = "Managed PostgreSQL endpoint used by application and Keycloak secrets"
  value       = aws_db_instance.postgresql.address
}

output "postgresql_database" {
  description = "Managed PostgreSQL database name"
  value       = aws_db_instance.postgresql.db_name
}

output "argocd_oidc_client_secret" {
  description = "Argo CD OIDC client secret seeded into cloud secret managers"
  value       = random_password.argocd_client.result
  sensitive   = true
}

output "argocd_admin_password" {
  description = "ArgoCD admin password stored in Secrets Manager under argocd/admin"
  value       = random_password.argocd_admin.result
  sensitive   = true
}

output "argocd_redis_password" {
  description = "ArgoCD Redis password stored in Secrets Manager under argocd/redis"
  value       = random_password.argocd_redis.result
  sensitive   = true
}

output "keycloak_ecr_repository_url" {
  description = "ECR repository Keycloak's quay.io image must be mirrored into before App Runner can start it"
  value       = aws_ecr_repository.keycloak.repository_url
}

output "keycloak_apprunner_service_url" {
  description = "App Runner default service URL for Keycloak"
  value       = aws_apprunner_service.keycloak.service_url
}

output "keycloak_custom_domain_certificate_validation_records" {
  description = "CNAME records that must be published via the keycloak-dns DNSEndpoint before the App Runner custom domain validates"
  value       = aws_apprunner_custom_domain_association.keycloak.certificate_validation_records
}
