# Cluster Issuer for Let's Encrypt
resource "kubernetes_manifest" "cluster_issuer" {
  count = var.install_cert_manager && var.create_cluster_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "${var.cert_manager_issuer_type}-letsencrypt"
    }
    spec = {
      acme = {
        server = var.cert_manager_issuer_type == "staging" ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "${var.cert_manager_issuer_type}-letsencrypt-key"
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

  depends_on = [
    helm_release.cert_manager,
    terraform_data.cert_manager_crds_ready,
    time_sleep.wait_for_cert_manager_crds_registration,
    terraform_data.kubernetes_ready
  ]
}


# ArgoCD Certificate
resource "kubernetes_manifest" "argocd_certificate" {
  count = var.install_argocd && var.enable_tls ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "argocd-tls-cert"
      namespace = var.argocd_namespace
    }
    spec = {
      secretName = "argocd-tls"
      issuerRef = {
        name = "${var.cert_manager_issuer_type}-letsencrypt"
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "argocd.${var.dns_zone_name}"
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.cluster_issuer,
    helm_release.argocd,
    terraform_data.kubernetes_ready
  ]
}



# Grafana Certificate
resource "kubernetes_manifest" "grafana_certificate" {
  count = var.install_grafana && var.enable_tls ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "grafana-tls-cert"
      namespace = var.grafana_namespace
    }
    spec = {
      secretName = "grafana-tls"
      issuerRef = {
        name = "${var.cert_manager_issuer_type}-letsencrypt"
        kind = "ClusterIssuer"
      }
      dnsNames = [
        "grafana.${var.dns_zone_name}"
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.cluster_issuer,
    helm_release.grafana,
    terraform_data.kubernetes_ready
  ]
}
