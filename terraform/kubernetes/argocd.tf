locals {
  argocd_domain = local.current_domain
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "argocd"
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd-${var.environment}"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.0.10"
  namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
  depends_on = [helm_release.cert_manager]
  create_namespace = false

  values = [
    yamlencode({
      global = {
        domain = local.argocd_domain
      }

      server = {
        extraArgs = [
          "--insecure",
        ]

        replicas = 1

        ingress = {
          enabled          = true
          ingressClassName = "nginx"
          hosts = [local.argocd_domain]
          paths = ["/"]
          pathType         = "Prefix"

          tls = [
            {
              hosts = [local.argocd_domain]
              secretName = "argocd-server-tls"
            }
          ]

          annotations = {
            "cert-manager.io/cluster-issuer"                 = var.cluster_issuer
            "kubernetes.io/tls-acme"                         = "true"
            "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
            "nginx.ingress.kubernetes.io/ssl-passthrough"    = "false"
            "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
          }
        }

        config = {
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
          "admin.enabled"                = "true"

          "server.insecure" = "true"
        }

        service = {
          type       = "ClusterIP"
          port       = 80
          targetPort = 8080
        }
      }

      redis = {
        enabled = true
      }

      repoServer = {
        replicas = 1
      }

      controller = {
        replicas = 1
      }

      applicationSet = {
        enabled  = true
        replicas = 1
      }

      configs = {
        tls = {
          server = {
            enabled = false
          }
        }

        cm = {
          "server.insecure" = "true"
        }
      }

      rbac = {
        create     = true
        pspEnabled = false
      }

      ha = {
        enabled = false
      }
    })
  ]
}
