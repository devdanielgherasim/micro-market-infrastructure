# Container Registry Module - variables.tf
# This file defines the variables used in the container registry module

variable "name" {
  description = "The name of the container registry"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the container registry"
  type        = string
}

variable "location" {
  description = "The Azure region where the container registry should be created"
  type        = string
}

variable "sku" {
  description = "The SKU name of the container registry. Possible values are Basic, Standard and Premium"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The SKU must be one of: Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Specifies whether the admin user is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the container registry"
  type        = map(string)
  default     = {}
}