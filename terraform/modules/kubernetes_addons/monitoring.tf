# Prometheus
resource "helm_release" "prometheus" {
  count = var.install_prometheus ? 1 : 0

  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = var.prometheus_version
  namespace        = var.prometheus_namespace
  create_namespace = true

  set {
    name  = "server.replicaCount"
    value = var.prometheus_replica_count
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = "true"
  }

  set {
    name  = "server.persistentVolume.size"
    value = "8Gi"
  }

  set {
    name  = "alertmanager.persistentVolume.enabled"
    value = "true"
  }

  set {
    name  = "alertmanager.persistentVolume.size"
    value = "2Gi"
  }

  set {
    name  = "alertmanager.replicaCount"
    value = var.prometheus_replica_count
  }

  depends_on = [
    helm_release.nginx_ingress,
    terraform_data.kubernetes_ready
  ]
}

# Grafana
resource "helm_release" "grafana" {
  count = var.install_grafana ? 1 : 0

  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = var.grafana_version
  namespace        = var.grafana_namespace
  create_namespace = true

  set {
    name  = "replicas"
    value = var.grafana_replica_count
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "5Gi"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "ingress.hosts[0]"
    value = "grafana.${var.dns_zone_name}"
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "ingress.tls[0].hosts[0]"
      value = "grafana.${var.dns_zone_name}"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "ingress.tls[0].secretName"
      value = "grafana-tls"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "${var.cert_manager_issuer_type}-letsencrypt"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "ingress.annotations.kubernetes\\.io/tls-acme"
      value = "true"
    }
  }

  # Configure Prometheus as a data source
  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://prometheus-server.${var.prometheus_namespace}.svc.cluster.local"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
    value = "true"
  }

  depends_on = [
    helm_release.nginx_ingress,
    helm_release.prometheus,
    kubernetes_manifest.cluster_issuer,
    terraform_data.kubernetes_ready
  ]
}
