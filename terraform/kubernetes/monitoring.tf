resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube-prometheus" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  version    = "72.6.3"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  set {
    name  = "grafana.assertNoLeakedSecrets"
    value = false
  }
  set {
    name  = "grafana.adminPassword"
    value = random_password.grafana_password.result
  }
  set {
    name  = "grafana.grafana\\.ini.server.domain"
    value = data.azurerm_public_ip.aks_public_ip.fqdn
  }
  set {
    name  = "grafana.grafana\\.ini.server.root_url"
    value = "${data.azurerm_public_ip.aks_public_ip.fqdn}/grafana"
  }
  set {
    name  = "grafana.grafana\\.ini.server.serve_from_sub_path"
    value = "true"
  }
}

resource "random_password" "grafana_password" {
  length = 16
}
