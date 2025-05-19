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

variable "nginx_ingress_version" {
  type        = string
  description = "The version of the NGINX Ingress Controller Helm chart."
  default     = "4.7.1"
}

variable "nginx_ingress_namespace" {
  type        = string
  description = "The Kubernetes namespace where the NGINX Ingress Controller will be installed."
  default     = "ingress-nginx"
}

variable "nginx_ingress_replica_count" {
  type        = number
  description = "The number of NGINX Ingress Controller replicas."
  default     = 1
}

variable "argocd_version" {
  type        = string
  description = "The version of the ArgoCD Helm chart."
  default     = "5.46.7"
}

variable "argocd_namespace" {
  type        = string
  description = "The Kubernetes namespace where ArgoCD will be installed."
  default     = "argocd"
}

variable "argocd_replica_count" {
  type        = number
  description = "The number of ArgoCD server replicas."
  default     = 1
}

variable "cert_manager_version" {
  type        = string
  description = "The version of the cert-manager Helm chart."
  default     = "v1.13.2"
}

variable "cert_manager_namespace" {
  type        = string
  description = "The Kubernetes namespace where cert-manager will be installed."
  default     = "cert-manager"
}

variable "cert_manager_replica_count" {
  type        = number
  description = "The number of cert-manager controller replicas."
  default     = 1
}

variable "prometheus_version" {
  type        = string
  description = "The version of the Prometheus Helm chart."
  default     = "25.8.0"
}

variable "prometheus_namespace" {
  type        = string
  description = "The Kubernetes namespace where Prometheus will be installed."
  default     = "monitoring"
}

variable "prometheus_replica_count" {
  type        = number
  description = "The number of Prometheus server replicas."
  default     = 1
}

variable "grafana_version" {
  type        = string
  description = "The version of the Grafana Helm chart."
  default     = "7.0.11"
}

variable "grafana_namespace" {
  type        = string
  description = "The Kubernetes namespace where Grafana will be installed."
  default     = "monitoring"
}

variable "grafana_replica_count" {
  type        = number
  description = "The number of Grafana server replicas."
  default     = 1
}

variable "cert_manager_email" {
  type        = string
  description = "The email address to use for Let's Encrypt certificate registration."
  default     = "admin@example.com"
}

variable "cert_manager_issuer_type" {
  type        = string
  description = "The type of Let's Encrypt issuer to use (staging or production)."
  default     = "staging"
}

variable "enable_tls" {
  type        = bool
  description = "Whether to enable TLS for ingress resources."
  default     = true
}
