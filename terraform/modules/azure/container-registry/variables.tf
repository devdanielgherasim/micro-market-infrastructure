variable "name" {
  type        = string
  description = "Name of the container registry"
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "sku" {
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  type        = bool
  default     = false
}
