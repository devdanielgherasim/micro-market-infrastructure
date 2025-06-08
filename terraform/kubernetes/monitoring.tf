resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "monitoring"
    }
  }
}

resource "random_password" "grafana_password" {
  length = 16
}

resource "kubernetes_secret_v1" "grafana_oauth_secret" {
  metadata {
    name      = "grafana-oauth"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "GRAFANA_OIDC_CLIENT_SECRET" = random_password.grafana_oidc_client_secret.result
    "DOMAIN"                     = local.current_domain
  }
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "57.1.0"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  depends_on = [helm_release.cert_manager]
  timeout    = 1200
  values     = [file("${path.root}/configs/kube-prometheus_config.yaml")]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.grafana_password.result
  }

  set {
    name  = "grafana.grafana\\.ini.server.domain"
    value = local.current_domain
  }

  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = "https://${local.current_domain}/grafana"
  }

  set {
    name  = "prometheus.prometheusSpec.externalLabels.cluster"
    value = var.environment
  }

  set_sensitive {
    name  = "grafana.envFromSecret"
    value = kubernetes_secret_v1.grafana_oauth_secret.metadata[0].name
  }
}
