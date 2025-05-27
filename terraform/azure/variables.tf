# Variables for Azure infrastructure project
variable "project_name" {
  type    = string
  default = "azure-infra"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "location" {
  type    = string
  default = "westeurope"
}
variable "acr_sku_name" {
  type    = string
  default = "Basic"
}
variable "kubernetes_version" {
  type    = string
  default = "1.26.0"
}
variable "aks_vm_size" {
  type    = string
  default = "Standard_DS2_v2"
}
variable "create_acr_role_assignment" {
  type    = bool
  default = true
}
variable "create_dns_zone" {
  type = bool
}
variable "dns_zone_name" {
  type = string
}
variable "tags" {
  type = map(string)
}

variable "node_count" {
  type    = number
  default = 1
}

variable "enable_auto_scaling" {
  type    = bool
  default = false
}
variable "min_count" {
  type    = number
  default = 1
}
variable "max_count" {
  type    = number
  default = 3
}
