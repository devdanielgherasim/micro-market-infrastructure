resource "kubernetes_namespace_v1" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }
}


resource "helm_release" "cert_manager" {
  name             = "cert-manager-${var.environment}"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.17.2"
  namespace        = kubernetes_namespace_v1.nginx.metadata[0].name
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.cluster_issuer
    }
    spec = {
      acme = {
        email  = "adriangherasim1@gmail.com"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-production"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress-${var.environment}"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = kubernetes_namespace_v1.nginx.metadata[0].name
  chart      = "ingress-nginx"
  version    = "4.12.2"

  values = [
    <<-EOT
    controller:
      replicaCount: 1
      admissionWebhooks:
        certManager:
          enabled: true
      metrics:
        enabled: true
        serviceMonitor:
          enabled: true
      service:
        externalTrafficPolicy: Local
        annotations:
          service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
      allowSnippetAnnotations: true
      config:
        enable-real-ip: "true"
        proxy-body-size: "20m"
        ssl-protocols: "TLSv1.2 TLSv1.3"
        ssl-ciphers: "HIGH:!aNULL:!MD5"
        hsts: "true"
        hsts-max-age: "31536000"
        hsts-include-subdomains: "true"
      resources:
        requests:
          cpu: 200m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi
    EOT
  ]

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_ingress_v1" "ingress_grafana" {
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer"                 = var.cluster_issuer
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/proxy-body-size"    = "20m"
      "acme.cert-manager.io/http01-edit-in-place"      = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }
  depends_on = [helm_release.nginx-ingress, helm_release.cert_manager, helm_release.kube-prometheus]

  spec {
    tls {
      hosts = ["${var.project_name}.westeurope.cloudapp.azure.com"]
      secret_name = "tls-secret-monitoring"
    }

    rule {
      host = "${var.project_name}.westeurope.cloudapp.azure.com"
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
