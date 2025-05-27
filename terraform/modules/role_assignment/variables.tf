# Role Assignment Module - variables.tf
# This file defines the variables used in the role assignment module

variable "principal_id" {
  description = "The ID of the principal (user, group, service principal, etc.) to assign the role to"
  type        = string
}

variable "role_definition_name" {
  description = "The name of the role to assign to the principal"
  type        = string
}

variable "scope" {
  description = "The scope at which the role assignment applies to, such as a resource ID"
  type        = string
}

variable "skip_service_principal_aad_check" {
  description = "If set to true, skips the Azure Active Directory check for the service principal in the tenant"
  type        = bool
  default     = true
}