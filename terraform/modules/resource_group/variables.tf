# Resource Group Module - variables.tf
# This file defines the variables used in the resource group module

variable "name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where the resource group should be created"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resource group"
  type        = map(string)
  default     = {}
}