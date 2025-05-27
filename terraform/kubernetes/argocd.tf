resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }

}

resource "helm_release" "argocd" {
  count = var.install_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

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
    value = data.azurerm_public_ip.aks_public_ip.fqdn
  }

  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = data.azurerm_public_ip.aks_public_ip.fqdn
  }

  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-tls"
  }

  set {
    name  = "server.ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "${var.cert_manager_issuer_type}-letsencrypt"
  }

  set {
    name  = "server.ingress.annotations.kubernetes\\.io/tls-acme"
    value = "true"
  }
}
