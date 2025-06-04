resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "random_password" "grafana_password" {
  length = 16
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "72.6.3"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  depends_on = [helm_release.cert_manager]

  values = [
    <<-EOT
    grafana:
      assertNoLeakedSecrets: false
      adminPassword: "${random_password.grafana_password.result}"
      grafana.ini:
        server:
          domain: "${local.current_domain}"
          root_url: "https://${local.current_domain}/grafana"
          serve_from_sub_path: true
      ingress:
        enabled: false
      serviceMonitor:
        enabled: true
    EOT
  ]
}
