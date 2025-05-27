# Variables for Azure infrastructure project
variable "project_name" {}
variable "environment" {}
variable "location" {}
variable "acr_sku_name" {}
variable "kubernetes_version" {}
variable "aks_vm_size" {}
variable "create_acr_role_assignment" { type = bool }
variable "create_dns_zone" { type = bool }
variable "dns_zone_name" {}
variable "tags" { type = map(string) }
