variable "name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for AKS."
  type        = string
}

variable "node_count" {
  description = "Number of default nodes."
  type        = number
}

variable "vm_size" {
  description = "VM Size for AKS nodes."
  type        = string
}

variable "tags" {
  description = "Tags for the cluster."
  type        = map(string)
}
