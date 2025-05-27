# Variables for Azure infrastructure project
variable "client_id" {
  type        = string
  description = "The Azure AD Application ID (Client ID) for authentication"
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "The Azure AD Application Secret (Client Secret) for authentication"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "The Azure AD Tenant ID for authentication"
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID where resources will be deployed"
  sensitive   = true
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
variable "kubernetes_version" {
  type    = string
  default = "1.26.0"
}
variable "aks_vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}
variable "create_acr_role_assignment" {
  type    = bool
  default = true
}
variable "create_dns_zone" {
  type = bool
}
variable "dns_zone_name" {
  type = string
}
variable "tags" {
  type = map(string)
}

variable "node_count" {
  type    = number
  default = 1
}
