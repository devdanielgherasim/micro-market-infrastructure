resource "helm_release" "argocd" {
  count = var.install_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = var.argocd_namespace
  create_namespace = true

  set {
    name  = "server.replicas"
    value = var.argocd_replica_count
  }

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.${var.dns_zone_name}"
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.tls[0].hosts[0]"
      value = "argocd.${var.dns_zone_name}"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.tls[0].secretName"
      value = "argocd-tls"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "${var.cert_manager_issuer_type}-letsencrypt"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.annotations.kubernetes\\.io/tls-acme"
      value = "true"
    }
  }

  depends_on = [
    helm_release.nginx_ingress,
    kubernetes_manifest.cluster_issuer,
    terraform_data.kubernetes_ready
  ]
}
