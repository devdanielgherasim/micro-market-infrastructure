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
