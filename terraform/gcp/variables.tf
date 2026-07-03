variable "project_id" {
  type        = string
  description = "The Google Cloud project ID"
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
  default     = "danielgherasim-microservices"
}

variable "environment" {
  type        = string
  description = "The environment (e.g., dev, prod)"
  default     = "dev"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default     = {}
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

variable "gitlab_project_path" {
  type        = string
  description = "GitLab project path allowed to federate into GCP Workload Identity Federation, for example group/project. Leave empty to skip CI identity federation."
  default     = ""
}

variable "gitlab_ref" {
  type        = string
  description = "Git ref allowed to use the GCP CI federated credential"
  default     = "main"
}
