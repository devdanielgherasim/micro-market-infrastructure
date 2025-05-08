variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string

}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aks_vm_size" {
  type        = string
  description = "The size of the AKS VM. Default is 'Standard_A2_v2'."
  default     = "Standard_A2_v2"

}

variable "acr_sku_name" {
  type        = string
  description = "The SKU of the Azure Container Registry. Default is 'Basic'."
  default     = "Basic"
}




