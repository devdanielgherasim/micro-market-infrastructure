resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = kubernetes_namespace_v1.nginx.metadata[0].name
  chart      = "ingress-nginx"
  version    = "4.12.2"
  set {
    name  = "controller.admissionWebhooks.certManager.enabled"
    value = "true"
  }
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }
  set {
    name  = "controller.replicaCount"
    value = "1"
  }
  set {
    name  = "controller.allowSnippetAnnotations"
    value = "true"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }
  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_namespace_v1" "nginx" {
  metadata {
    name = "nginx"
  }

}

# Cert Manager
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.17.2"
  namespace        = kubernetes_namespace_v1.nginx.metadata[0].name
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_ingress_v1" "ignis_ingress_grafana" {
  metadata {
    name      = "ignis-grafana-ingress"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer"              = "letsencrypt-production-cluster-issuer"
      "kubernetes.io/ingress.class"                 = "nginx"
      "nginx.ingress.kubernetes.io/use-regex"       = "true"
      "nginx.ingress.kubernetes.io/proxy-body-size" = "20m"
      "acme.cert-manager.io/http01-edit-in-place"   = "true"
    }
  }

  spec {
    tls {
      hosts       = [data.azurerm_public_ip.aks_public_ip.fqdn]
      secret_name = "tls-secret-monitoring"
    }

    rule {
      host = data.azurerm_public_ip.aks_public_ip.fqdn
      http {
        path {
          path_type = "Prefix"
          path      = "/grafana"
          backend {
            service {
              name = "kube-prometheus-stack-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
