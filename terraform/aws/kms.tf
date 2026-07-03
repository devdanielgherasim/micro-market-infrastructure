# Customer-managed KMS key used for envelope encryption of Kubernetes secrets (etcd).

resource "aws_kms_key" "eks_secrets" {
  description             = "Envelope encryption of Kubernetes secrets for ${local.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${local.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}

resource "aws_kms_key" "ecr" {
  description             = "Encryption key for ECR repositories in ${local.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${local.cluster_name}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}
