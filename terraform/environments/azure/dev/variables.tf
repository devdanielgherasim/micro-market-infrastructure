variable "client_id" {
  type        = string
  description = "Azure AD Application Client ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "resource_group_name" {
  type        = string
  description = "Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure Region"
}
