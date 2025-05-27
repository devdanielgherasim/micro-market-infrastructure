# Kubernetes Module - variables.tf
# This file defines the variables used in the kubernetes module

variable "name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "The Azure region where the AKS cluster should be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix specified when creating the managed cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes specified when creating the AKS managed cluster"
  type        = string
  default     = null
}

variable "default_node_pool_name" {
  description = "The name of the default node pool"
  type        = string
  default     = "default"
}

variable "node_count" {
  description = "The number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "The size of the Virtual Machine in the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "enable_auto_scaling" {
  description = "Whether to enable auto-scaling for the default node pool"
  type        = bool
  default     = false
}

variable "min_count" {
  description = "The minimum number of nodes in the default node pool when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "The maximum number of nodes in the default node pool when auto-scaling is enabled"
  type        = number
  default     = 3
}

variable "os_disk_size_gb" {
  description = "The size of the OS disk in GB for each node in the default node pool"
  type        = number
  default     = 30
}

variable "tags" {
  description = "A mapping of tags to assign to the AKS cluster"
  type        = map(string)
  default     = {}
}

