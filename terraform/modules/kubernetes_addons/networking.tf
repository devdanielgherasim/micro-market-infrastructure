# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  count = var.install_nginx_ingress ? 1 : 0

  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.nginx_ingress_version
  namespace        = var.nginx_ingress_namespace
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.replicaCount"
    value = var.nginx_ingress_replica_count
  }

  depends_on = [
    terraform_data.kubernetes_ready
  ]
}

# Cert Manager
resource "helm_release" "cert_manager" {
  count = var.install_cert_manager ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = var.cert_manager_namespace
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = var.cert_manager_replica_count
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  depends_on = [
    helm_release.nginx_ingress,
    terraform_data.kubernetes_ready
  ]
}
