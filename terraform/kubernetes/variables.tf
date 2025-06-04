variable "cloud_provider" {
  type        = string
  description = "The cloud provider to use (azure or gcp)"
  default     = "azure"
  validation {
    condition = contains(["azure", "gcp"], var.cloud_provider)
    error_message = "The cloud_provider value must be 'azure' or 'gcp'."
  }
}
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
variable "gcp_project" {
  type        = string
  description = "The Google Cloud project ID"
  default     = ""
}
variable "gcp_region" {
  type        = string
  description = "The Google Cloud region where resources will be deployed"
  default     = "europe-central2"
}
variable "gcp_zone" {
  type        = string
  description = "The Google Cloud zone where resources will be deployed"
  default     = "europe-central2-a"
}
variable "gcp_credentials" {
  type        = string
  description = "The path to the Google Cloud credentials file"
  default     = ""
  sensitive   = true
}
variable "project_name" {
  type    = string
  default = "cloud-infra"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "cluster_issuer" {
  type    = string
  default = "letsencrypt-production-cluster-issuer"
}