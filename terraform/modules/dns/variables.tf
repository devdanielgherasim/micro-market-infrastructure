# DNS Module - variables.tf
# This file defines the variables used in the dns module

variable "create_resource_group" {
  description = "Whether to create a new resource group for the DNS zone"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the DNS zone"
  type        = string
}

variable "location" {
  description = "The Azure region where the resource group should be created"
  type        = string
}

variable "zone_name" {
  description = "The name of the DNS zone"
  type        = string
}

variable "a_records" {
  description = "A map of A records to create in the DNS zone"
  type = map(object({
    ttl               = number
    records           = optional(list(string))
    target_resource_id = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
