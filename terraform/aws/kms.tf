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

  # EKS node group ASGs launch EC2 instances with encrypted EBS volumes.
  # The ASG service-linked role must be able to create KMS grants so that
  # EC2 can encrypt/decrypt the node root volume at launch time.
  # Without this, instances fail with InvalidKMSKey.InvalidState.
  statement {
    sid       = "AllowAutoScalingServiceLinkedRole"
    effect    = "Allow"
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }
  }

  statement {
    sid       = "AllowAutoScalingServiceLinkedRoleGrant"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
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
