resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd-${var.environment}"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.0.10"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  set {
    name  = "server.replicas"
    value = "1"
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
    value = "${var.project_name}.westeurope.cloudapp.azure.com"
  }

  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "${var.project_name}.westeurope.cloudapp.azure.com"
  }
  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argocd-tls"
  }

  set {
    name  = "server.ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = var.cluster_issuer
  }

  set {
    name  = "server.ingress.annotations.kubernetes\\.io/tls-acme"
    value = "true"
  }
}
