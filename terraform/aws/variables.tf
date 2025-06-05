variable "access_key" {
  type        = string
  description = "AWS Access Key for authentication"
  sensitive   = true
}

variable "secret_key" {
  type        = string
  description = "AWS Secret Key for authentication"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "AWS Region where resources will be deployed"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "aws-infra"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod, etc.)"
  default     = "dev"
}

variable "eks_node_instance_type" {
  type        = string
  description = "EC2 instance type for EKS nodes"
  default     = "t3.medium"
}

variable "eks_node_count" {
  type        = number
  description = "Number of nodes in EKS cluster"
  default     = 2
}

variable "eks_node_disk_size" {
  type        = number
  description = "Disk size for EKS nodes in GB"
  default     = 30
}

variable "subnet_count" {
  type        = number
  description = "Number of subnets to create for EKS"
  default     = 2
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
variable "session_token" {
  description = "AWS session token for temporary credentials"
  type        = string
  sensitive   = true
}
variable "eks_cluster_role_name" {
  description = "Name of the existing IAM role for EKS cluster in your lab environment"
  type        = string
  default     = "LabRole"
}

variable "eks_node_role_name" {
  description = "Name of the existing IAM role for EKS node group in your lab environment"
  type        = string
  default     = "LabRole"
}