variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "The address space that is used for the virtual network."
  type        = list(string)
}

variable "location" {
  description = "The Azure Region to deploy the resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "subnet_prefixes" {
  description = "Subnets with names and prefixes."
  type = list(object({
    name   = string
    prefix = string
  }))
}
