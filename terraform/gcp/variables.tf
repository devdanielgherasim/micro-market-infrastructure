variable "project_id" {
  type        = string
  description = "The Google Cloud project ID"
}

variable "credentials_file" {
  type        = string
  description = "Path to the Google Cloud credentials file"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "The Google Cloud region where resources will be deployed"
  default     = "europe-west3"
}

variable "zone" {
  type        = string
  description = "The Google Cloud zone where resources will be deployed"
  default     = "europe-west3-a"
}

variable "project_name" {
  type        = string
  description = "The name of the project"
  default     = "microservices1691715"
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
  default     = "dev"
}

variable "labels" {
  type = map(string)
  description = "Labels to apply to resources"
  default = {}
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the GKE cluster"
  default     = 1
}

variable "machine_type" {
  type        = string
  description = "Machine type for GKE nodes"
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB for GKE nodes"
  default     = 50
}

variable "disk_type" {
  type        = string
  description = "Disk type for GKE nodes"
  default     = "pd-standard"
}

variable "auto_repair" {
  type        = bool
  description = "Enable auto repair for GKE nodes"
  default     = true
}

variable "auto_upgrade" {
  type        = bool
  description = "Enable auto upgrade for GKE nodes"
  default     = true
}

variable "domain_suffix" {
  type        = string
  description = "The domain suffix to use for DNS"
  default     = "nip.io"
}

variable "service_account_email" {
  type        = string
  description = "The email address of the service account that needs access to the GKE cluster"
  default     = ""
}

variable "deletion_protection" {
  type        = bool
  description = "The deletion protection flag"
  default     = true
}