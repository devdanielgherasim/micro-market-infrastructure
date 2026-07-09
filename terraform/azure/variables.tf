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
  description = <<-EOT
    CIDR blocks allowed to reach the AKS public API server endpoint.

    SECURITY: An empty list (default) leaves the API server fully public —
    this is a known security gap accepted only for initial bootstrapping.
    For any environment beyond initial setup, populate this with the
    operator's home/office IP and any CI runner egress IPs, e.g.:
      api_allowed_cidrs = ["<your-ip>/32", "<ci-runner-ip>/32"]
    This restricts kubectl/API access to those ranges only.

    A private cluster (api_server_access_profile with private_cluster_enabled)
    would be the next hardening step but requires a custom VNet + VPN/bastion.
  EOT
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

variable "manage_postgresql_roles" {
  type        = bool
  description = "Manage application PostgreSQL roles, schemas, and grants through the PostgreSQL provider. Keep false for normal Azure applies because the PostgreSQL Flexible Server is private-only and Terraform runners outside the VNet cannot resolve or reach it; set true only when running Terraform from a network path with private DNS access to the server (e.g. a bastion/VPN inside the VNet). The recommended, repeatable path for provisioning catalog_svc/orders_svc/audit_svc is the in-cluster ArgoCD Sync-hook Job in platform-gitops/platform/postgres-app-roles (see platform-gitops/plans/2026-07-09-postgres-app-role-job.md) - AKS already has VNet peering + private DNS access to this server, so it needs no bastion. Do not set this true while that Job is also managing the same server: Terraform doesn't know about roles the Job creates out-of-band, so postgresql_role creation will fail with 'role already exists' unless state is reconciled first (e.g. via terraform import)."
  default     = false
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

variable "secondary_location" {
  type        = string
  description = "Azure region for resources that don't need to co-locate with AKS (managed PostgreSQL, Keycloak's Container Apps Environment). Deliberately separate from `location`: this subscription's free-tier regional vCPU quota is per-region, so a second region gives these resources their own independent quota pool instead of competing with AKS nodes for the same 4-vCPU cap. Region eligibility for this subscription is opaque and only surfaces at apply time (seen live: germanywestcentral rejects Postgres Flexible Server with LocationIsOfferRestricted; westeurope rejected everything with RequestDisallowedByAzure/\"not accepting new customers\") - if northeurope also gets rejected, try overriding with `-var secondary_location=swedencentral` or `-var secondary_location=eastus` rather than editing this file again."
  default     = "northeurope"
}

variable "keycloak_custom_domain_enabled" {
  type        = bool
  description = "Second phase of Keycloak's Container Apps custom-domain apply (ADR-19): leave false on the first apply, populate the keycloak-dns DNSEndpoint in platform-gitops from the keycloak_custom_domain_verification_id/keycloak_default_hostname outputs, then flip to true once those DNS records resolve to bind the custom domain and provision the managed certificate."
  default     = false
}
