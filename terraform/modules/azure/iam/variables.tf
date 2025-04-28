variable "principal_id" {
  description = "The ID of the Principal (service principal or managed identity)"
  type        = string
}

variable "role_definition_name" {
  description = "The name of the Role to assign"
  type        = string
}

variable "scope" {
  description = "The scope for the role assignment"
  type        = string
}
