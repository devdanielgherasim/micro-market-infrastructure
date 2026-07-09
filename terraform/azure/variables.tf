variable "client_id" {
  type        = string
  description = "The Azure AD Application ID (Client ID) for authentication"
  sensitive   = true
  default     = ""
}
variable "client_secret" {
  type        = string
  description = "The Azure AD Application Secret (Client Secret) for authentication"
  sensitive   = true
  default     = ""
}
variable "tenant_id" {
  type        = string
  description = "The Azure AD Tenant ID for authentication"
  sensitive   = true
  default     = ""
}
variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID where resources will be deployed"
  sensitive   = true
  default     = ""
}
variable "project_name" {
  type    = string
  default = "azure-infra"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "location" {
  type    = string
  default = "westeurope"
}
variable "acr_sku_name" {
  type    = string
  default = "Basic"
}
variable "aks_vm_size" {
  type    = string
  default = "Standard_F4s_v2"
}
variable "tags" {
  type        = map(string)
  description = "Tags applied to Azure resources"
  default     = {}
}

variable "node_count" {
  type        = number
  description = "Initial number of nodes in the node pool"
  default     = 1
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of nodes in the node pool when autoscaling"
  default     = 1
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of nodes in the node pool when autoscaling"
  default     = 3
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the AKS cluster. Leave null to let Azure choose the regional default."
  nullable    = true
  default     = null
}

variable "azure_policy_enabled" {
  type        = bool
  description = "Enable the AKS Azure Policy add-on. Disable only for free-quota demo clusters where Gatekeeper's CPU overhead prevents scheduling the platform."
  default     = true
}

variable "api_allowed_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the AKS public API server endpoint. Empty list (default) leaves the API server fully public, matching prior behavior; populate to restrict it to known operator/CI ranges, mirroring aws/variables.tf's api_allowed_cidrs."
  default     = []

  validation {
    condition     = !contains(var.api_allowed_cidrs, "0.0.0.0/0")
    error_message = "Do not add 0.0.0.0/0 to api_allowed_cidrs; leave the list empty instead to keep the API server public, since AKS's authorized_ip_ranges does not treat 0.0.0.0/0 as a no-op the way an omitted block does."
  }
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
  description = "GitLab project path allowed to federate into the Azure CI identity, for example group/project. Leave empty to skip CI identity federation."
  default     = ""
}

variable "gitlab_ref" {
  type        = string
  description = "Git ref allowed to use the Azure CI federated credential"
  default     = "main"
}

variable "github_repos" {
  type        = list(string)
  description = "GitHub \"org/repo\" paths allowed to federate into a dedicated Azure CI identity via OIDC (one federated credential per repo, scoped to AcrPush only). Empty list (default) skips CI identity federation."
  default     = []
}

variable "github_ref" {
  type        = string
  description = "Git ref allowed to use the Azure GitHub CI federated credential, e.g. refs/heads/main"
  default     = "refs/heads/main"
}
