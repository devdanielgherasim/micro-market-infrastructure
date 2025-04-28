variable "release_name" {
  default = "argocd"
}

variable "namespace" {
  default = "argocd"
}

variable "chart_version" {
  description = "Version of the ArgoCD Helm chart"
  default     = "5.51.2"
}
