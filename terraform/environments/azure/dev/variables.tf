variable "resource_group_name" {
  description = "Azure resource group name."
  type        = string
}

variable "location" {
  description = "Azure location."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
}

variable "client_id" {
  description = "Client id."
  type        = string
}

variable "subscription_id" {
  description = "subscription_id"
  type        = string
}

variable "tenant_id" {
  description = "tenant_id"
  type        = string
}
