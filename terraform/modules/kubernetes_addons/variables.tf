# Kubernetes Addons Module - variables.tf
# This file defines the variables used in the kubernetes_addons module

# General
variable "dns_zone_name" {
  description = "The name of the DNS zone"
  type        = string
  default     = ""
}

variable "enable_tls" {
  description = "Whether to enable TLS for ingress resources"
  type        = bool
  default     = true
}

# NGINX Ingress Controller
variable "install_nginx_ingress" {
  description = "Whether to install NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "nginx_ingress_version" {
  description = "The version of the NGINX Ingress Controller Helm chart"
  type        = string
  default     = "4.7.1"
}

variable "nginx_ingress_namespace" {
  description = "The Kubernetes namespace where the NGINX Ingress Controller will be installed"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_ingress_replica_count" {
  description = "The number of NGINX Ingress Controller replicas"
  type        = number
  default     = 1
}

# Cert Manager
variable "install_cert_manager" {
  description = "Whether to install cert-manager"
  type        = bool
  default     = true
}

variable "cert_manager_version" {
  description = "The version of the cert-manager Helm chart"
  type        = string
  default     = "v1.13.2"
}

variable "cert_manager_namespace" {
  description = "The Kubernetes namespace where cert-manager will be installed"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_replica_count" {
  description = "The number of cert-manager controller replicas"
  type        = number
  default     = 1
}

variable "create_cluster_issuer" {
  description = "Whether to create a ClusterIssuer for Let's Encrypt"
  type        = bool
  default     = true
}

variable "cert_manager_issuer_type" {
  description = "The type of Let's Encrypt issuer to use (staging or production)"
  type        = string
  default     = "staging"
  
  validation {
    condition     = contains(["staging", "production"], var.cert_manager_issuer_type)
    error_message = "The cert_manager_issuer_type must be one of: staging, production."
  }
}

variable "cert_manager_email" {
  description = "The email address to use for Let's Encrypt certificate registration"
  type        = string
  default     = "admin@example.com"
}

# ArgoCD
variable "install_argocd" {
  description = "Whether to install ArgoCD"
  type        = bool
  default     = true
}

variable "argocd_version" {
  description = "The version of the ArgoCD Helm chart"
  type        = string
  default     = "5.46.7"
}

variable "argocd_namespace" {
  description = "The Kubernetes namespace where ArgoCD will be installed"
  type        = string
  default     = "argocd"
}

variable "argocd_replica_count" {
  description = "The number of ArgoCD server replicas"
  type        = number
  default     = 1
}

# Prometheus
variable "install_prometheus" {
  description = "Whether to install Prometheus"
  type        = bool
  default     = true
}

variable "prometheus_version" {
  description = "The version of the Prometheus Helm chart"
  type        = string
  default     = "25.8.0"
}

variable "prometheus_namespace" {
  description = "The Kubernetes namespace where Prometheus will be installed"
  type        = string
  default     = "monitoring"
}

variable "prometheus_replica_count" {
  description = "The number of Prometheus server replicas"
  type        = number
  default     = 1
}

# Grafana
variable "install_grafana" {
  description = "Whether to install Grafana"
  type        = bool
  default     = true
}

variable "grafana_version" {
  description = "The version of the Grafana Helm chart"
  type        = string
  default     = "7.0.11"
}

variable "grafana_namespace" {
  description = "The Kubernetes namespace where Grafana will be installed"
  type        = string
  default     = "monitoring"
}

variable "grafana_replica_count" {
  description = "The number of Grafana server replicas"
  type        = number
  default     = 1
}