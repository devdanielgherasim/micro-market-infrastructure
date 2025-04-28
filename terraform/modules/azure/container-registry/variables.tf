variable "name" {
  description = "The name of the container registry"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group for the ACR"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "sku" {
  description = "The SKU of the container registry (e.g. Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  description = "Whether admin user is enabled"
  type        = bool
  default     = false
}
