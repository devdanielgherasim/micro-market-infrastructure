resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    # Worker nodes live in the private subnets only.
    subnet_ids = aws_subnet.private[*].id

    # API endpoint: public but restricted to the allowed CIDRs;
    # nodes reach the control plane over the private endpoint.
    endpoint_public_access  = length(var.api_allowed_cidrs) > 0
    endpoint_private_access = true
    public_access_cidrs     = var.api_allowed_cidrs
  }

  # Envelope encryption of Kubernetes secrets with a customer-managed KMS key.
  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# Launch template: enforces IMDSv2 (http_tokens=required) and moves disk
# configuration here so it can be encrypted with the cluster KMS key.
# hop_limit=2 is required so pods inside containers can reach the metadata
# endpoint for IRSA token exchange (container adds one hop).
resource "aws_launch_template" "eks_nodes" {
  name_prefix = "lt-${local.cluster_name}-"
  description = "Worker node launch template for ${local.cluster_name}"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.eks_node_disk_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks_secrets.arn
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, { Name = "node-${local.cluster_name}" })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.tags, { Name = "vol-${local.cluster_name}" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ng-${var.project_name}-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  version         = var.kubernetes_version

  scaling_config {
    min_size     = var.eks_node_min_count
    desired_size = var.eks_node_desired_count
    max_size     = var.eks_node_max_count
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = [var.eks_node_instance_type]

  launch_template {
    id      = aws_launch_template.eks_nodes.id
    version = aws_launch_template.eks_nodes.latest_version
  }

  # Let the cluster autoscaler manage desired_size after creation.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
    aws_nat_gateway.this,
  ]
}

# --- Managed cluster addons ---

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}
