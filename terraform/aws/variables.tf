variable "region" {
  type        = string
  description = "AWS region where resources will be deployed"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project; used as a prefix for all resource names"
  default     = "danielgherasim-microservices"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the EKS control plane and node group"
  default     = "1.33"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to spread subnets across"
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 (EKS requires subnets in at least two AZs)."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT gateway for all private subnets (cost saving) instead of one per AZ (higher availability)"
  default     = true
}

variable "api_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the public EKS API endpoint. Use an empty list to disable public API access."
  default     = ["0.0.0.0/0"]

  validation {
    condition     = var.environment == "dev" || !contains(var.api_allowed_cidrs, "0.0.0.0/0")
    error_message = "Only dev may use 0.0.0.0/0 for EKS API access. Use explicit operator/CI CIDRs or an empty list for private-only access."
  }
}

variable "eks_node_instance_type" {
  type        = string
  description = "EC2 instance type for EKS worker nodes"
  default     = "t3.large"
}

variable "eks_node_min_count" {
  type        = number
  description = "Minimum number of worker nodes (cluster autoscaler lower bound)"
  default     = 1
}

variable "eks_node_desired_count" {
  type        = number
  description = "Initial desired number of worker nodes"
  default     = 2
}

variable "eks_node_max_count" {
  type        = number
  description = "Maximum number of worker nodes (cluster autoscaler upper bound)"
  default     = 3
}

variable "eks_node_disk_size" {
  type        = number
  description = "Root disk size for EKS worker nodes in GB"
  default     = 50
}

variable "application_names" {
  type        = list(string)
  description = "Application names for which an ECR repository is created"
  default     = ["catalog", "orders", "audit", "micro-market-frontend", "java21-docker-azcli"]
}

variable "ecr_kept_images" {
  type        = number
  description = "Number of most recent images retained per ECR repository by the lifecycle policy"
  default     = 10
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources"
  default     = {}
}

variable "database_name" {
  type        = string
  description = "Shared PostgreSQL database name seeded into cloud secret managers"
  default     = "microservices"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Scoped Cloudflare API token for DNS automation and DNS-01 validation"
  sensitive   = true
  default     = ""
}
