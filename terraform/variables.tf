# Variables for the root module
# This file defines all the variables used in the main.tf file

# Azure Authentication Variables
variable "client_id" {
  type        = string
  description = "The Azure AD Application ID (Client ID) for authentication"
  sensitive   = true
}

variable "client_secret" {
  type        = string
  description = "The Azure AD Application Secret (Client Secret) for authentication"
  sensitive   = true
}

variable "tenant_id" {
  type        = string
  description = "The Azure AD Tenant ID for authentication"
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID where resources will be deployed"
  sensitive   = true
}

# General Configuration Variables
variable "location" {
  type        = string
  description = "The Azure region where resources will be deployed"
  default     = "westeurope"
}

variable "project_name" {
  type        = string
  description = "The name of the project, used in resource naming"
  validation {
    condition     = length(var.project_name) > 0
    error_message = "The project_name value must not be empty."
  }
}

variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, test, prod)"
  validation {
    condition = contains(["dev", "test", "prod"], var.environment)
    error_message = "The environment must be one of: dev, test, prod."
  }
}

variable "tags" {
  type = map(string)
  description = "A map of tags to apply to all resources"
  default = {}
}

# Azure Container Registry Variables
variable "acr_sku_name" {
  type        = string
  description = "The SKU of the Azure Container Registry. Default is 'Basic'."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku_name)
    error_message = "The ACR SKU must be one of: Basic, Standard, Premium."
  }
}

# Azure Kubernetes Service Variables
variable "kubernetes_version" {
  type        = string
  description = "The version of Kubernetes to use for the AKS cluster. If not specified, the latest version will be used."
  default     = null
}

variable "aks_vm_size" {
  type        = string
  description = "The size of the Virtual Machine in the AKS node pool"
  default     = "Standard_D2s_v3"
}

variable "create_acr_role_assignment" {
  type        = bool
  description = "Whether to create a role assignment for AKS to pull images from ACR"
  default     = true
}

# DNS Configuration Variables
variable "create_dns_zone" {
  type        = bool
  description = "Whether to create a new DNS zone"
  default     = false
}

variable "dns_zone_name" {
  type        = string
  description = "The name of the DNS zone"
  default     = ""
}

# Kubernetes Resources Variables
variable "create_kubernetes_resources" {
  type        = bool
  description = "Whether to create Kubernetes resources (addons, etc.)"
  default     = true
}

variable "enable_tls" {
  type        = bool
  description = "Whether to enable TLS for ingress resources"
  default     = true
}

# NGINX Ingress Controller Variables
variable "nginx_ingress_version" {
  type        = string
  description = "The version of the NGINX Ingress Controller Helm chart"
  default     = "4.7.1"
}

variable "nginx_ingress_namespace" {
  type        = string
  description = "The Kubernetes namespace where the NGINX Ingress Controller will be installed"
  default     = "ingress-nginx"
}

variable "nginx_ingress_replica_count" {
  type        = number
  description = "The number of NGINX Ingress Controller replicas"
  default     = 1
}

# Cert Manager Variables
variable "cert_manager_version" {
  type        = string
  description = "The version of the cert-manager Helm chart"
  default     = "v1.13.2"
}

variable "cert_manager_namespace" {
  type        = string
  description = "The Kubernetes namespace where cert-manager will be installed"
  default     = "cert-manager"
}

variable "cert_manager_replica_count" {
  type        = number
  description = "The number of cert-manager controller replicas"
  default     = 1
}

variable "cert_manager_email" {
  type        = string
  description = "The email address to use for Let's Encrypt certificate registration"
  default     = "admin@example.com"
}

variable "cert_manager_issuer_type" {
  type        = string
  description = "The type of Let's Encrypt issuer to use (staging or production)"
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.cert_manager_issuer_type)
    error_message = "The cert_manager_issuer_type must be one of: staging, production."
  }
}

# ArgoCD Variables
variable "argocd_version" {
  type        = string
  description = "The version of the ArgoCD Helm chart"
  default     = "5.46.7"
}

variable "argocd_namespace" {
  type        = string
  description = "The Kubernetes namespace where ArgoCD will be installed"
  default     = "argocd"
}

variable "argocd_replica_count" {
  type        = number
  description = "The number of ArgoCD server replicas"
  default     = 1
}

# Prometheus Variables
variable "prometheus_version" {
  type        = string
  description = "The version of the Prometheus Helm chart"
  default     = "25.8.0"
}

variable "prometheus_namespace" {
  type        = string
  description = "The Kubernetes namespace where Prometheus will be installed"
  default     = "monitoring"
}

variable "prometheus_replica_count" {
  type        = number
  description = "The number of Prometheus server replicas"
  default     = 1
}

# Grafana Variables
variable "grafana_version" {
  type        = string
  description = "The version of the Grafana Helm chart"
  default     = "7.0.11"
}

variable "grafana_namespace" {
  type        = string
  description = "The Kubernetes namespace where Grafana will be installed"
  default     = "monitoring"
}

variable "grafana_replica_count" {
  type        = number
  description = "The number of Grafana server replicas"
  default     = 1
}
