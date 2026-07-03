locals {
  cluster_name = "eks-${var.project_name}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}
