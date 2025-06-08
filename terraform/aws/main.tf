locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}

resource "aws_ecr_repository" "this" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = merge(local.tags, {
    Name = "vpc-${var.project_name}-${var.environment}"
  })
}

resource "aws_subnet" "eks" {
  count = var.subnet_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "${var.region}${["a", "b", "c"][count.index % 3]}"
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "subnet-${var.project_name}-${var.environment}-${count.index}"
    "kubernetes.io/cluster/eks-${var.project_name}-${var.environment}" = "shared"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "igw-${var.project_name}-${var.environment}"
  })
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.tags, {
    Name = "rt-${var.project_name}-${var.environment}"
  })
}

resource "aws_route_table_association" "this" {
  count = var.subnet_count

  subnet_id      = aws_subnet.eks[count.index].id
  route_table_id = aws_route_table.this.id
}

data "aws_iam_role" "eks_lab_role" {
  name = var.eks_cluster_role_name
}

resource "aws_eks_cluster" "this" {
  name     = "eks-${var.project_name}-${var.environment}"
  role_arn = data.aws_iam_role.eks_lab_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids = aws_subnet.eks[*].id
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  tags = local.tags
}

data "aws_iam_role" "eks_node_lab_role" {
  name = var.eks_node_role_name
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ng-${var.project_name}-${var.environment}"
  node_role_arn   = data.aws_iam_role.eks_node_lab_role.arn
  subnet_ids      = aws_subnet.eks[*].id

  scaling_config {
    desired_size = var.eks_node_count
    max_size     = var.eks_node_count
    min_size     = var.eks_node_count
  }

  instance_types = [var.eks_node_instance_type]
  disk_size      = var.eks_node_disk_size

  tags = local.tags
}

resource "aws_secretsmanager_secret" "certificate_secret" {
  name        = "${var.project_name}-${var.environment}-certificate"
  description = "Secret for storing TLS certificate for ${var.project_name} in ${var.environment}"

  tags = local.tags
}

resource "aws_secretsmanager_secret_policy" "certificate_secret_policy" {
  secret_arn = aws_secretsmanager_secret.certificate_secret.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_iam_role.eks_node_lab_role.arn
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}
