# Customer-managed KMS key used for envelope encryption of Kubernetes secrets (etcd).

data "aws_caller_identity" "current" {}

# Explicit key policies below replicate AWS's own default key policy
# ("Enable IAM User Permissions": full account root access, delegating
# actual authorization to IAM policies) so behavior is unchanged from the
# implicit default, while satisfying the requirement that KMS keys carry an
# explicit, auditable policy document (checkov CKV2_AWS_64).
data "aws_iam_policy_document" "eks_secrets_key" {
  statement {
    sid       = "EnableIamUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "eks_secrets" {
  description             = "Envelope encryption of Kubernetes secrets for ${local.cluster_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.eks_secrets_key.json
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${local.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}

data "aws_iam_policy_document" "ecr_key" {
  statement {
    sid       = "EnableIamUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "ecr" {
  description             = "Encryption key for ECR repositories in ${local.cluster_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.ecr_key.json
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${local.cluster_name}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}
