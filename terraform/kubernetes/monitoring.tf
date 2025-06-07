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
  values     = [file("${path.module}/configs/kube-prometheus_config.yaml")]
  depends_on = [helm_release.cert_manager]

  # Output Grafana admin password for reference
  set {
    name  = "grafana.adminPassword"
    value = random_password.grafana_password.result
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.11"
  depends_on = [helm_release.cert_manager, helm_release.kube-prometheus]

  values = [
    <<-EOT
    loki:
      auth_enabled: false
      storage:
        type: filesystem
      serviceMonitor:
        enabled: true
      config:
        limits_config:
          retention_period: 168h
        schema_config:
          configs:
            - from: 2020-10-24
              store: boltdb-shipper
              object_store: filesystem
              schema: v11
              index:
                prefix: index_
                period: 24h
      service:
        port: 3100
        type: ClusterIP
      gateway:
        enabled: true
        service:
          type: ClusterIP
          port: 80
    promtail:
      enabled: true
      serviceMonitor:
        enabled: true
      config:
        logLevel: info
        serverPort: 3101
        clients:
          - url: http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push
    grafana:
      enabled: false
    EOT
  ]
}
