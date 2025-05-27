# Kubernetes Addons Module - main.tf
# This module installs various Kubernetes addons using Helm

# Wait for Kubernetes to be ready
resource "time_sleep" "wait_for_kubernetes" {
  create_duration = "30s"
}

# This resource ensures that the Kubernetes provider is initialized after the time_sleep
resource "terraform_data" "kubernetes_ready" {
  depends_on = [time_sleep.wait_for_kubernetes]
}

# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  count = var.install_nginx_ingress ? 1 : 0

  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.nginx_ingress_version
  namespace        = var.nginx_ingress_namespace
  create_namespace = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.replicaCount"
    value = var.nginx_ingress_replica_count
  }

  depends_on = [
    terraform_data.kubernetes_ready
  ]
}

# Cert Manager
resource "helm_release" "cert_manager" {
  count = var.install_cert_manager ? 1 : 0

  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = var.cert_manager_namespace
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = var.cert_manager_replica_count
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  depends_on = [
    helm_release.nginx_ingress,
    terraform_data.kubernetes_ready
  ]
}

# Ensure cert-manager CRDs are fully established
resource "terraform_data" "cert_manager_crds_ready" {
  count = var.install_cert_manager ? 1 : 0

  # This trigger ensures that this resource is recreated whenever the cert-manager Helm release changes
  triggers_replace = {
    cert_manager_installed = join(",", [for r in helm_release.cert_manager : r.id])
  }

  # This input ensures that this resource depends on the cert-manager Helm release
  input = join(",", [for r in helm_release.cert_manager : r.id])

  # This lifecycle block ensures that this resource is created after the cert-manager Helm release
  lifecycle {
    replace_triggered_by = [
      helm_release.cert_manager
    ]
  }
}

# Additional wait time for cert-manager CRDs to be fully registered with the API server
resource "time_sleep" "wait_for_cert_manager_crds_registration" {
  count = var.install_cert_manager ? 1 : 0

  depends_on = [
    terraform_data.cert_manager_crds_ready
  ]
  create_duration = "180s"
}

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

# ArgoCD
resource "helm_release" "argocd" {
  count = var.install_argocd ? 1 : 0

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = var.argocd_namespace
  create_namespace = true

  set {
    name  = "server.replicas"
    value = var.argocd_replica_count
  }

  set {
    name  = "server.service.type"
    value = "ClusterIP"
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
    value = "argocd.${var.dns_zone_name}"
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.tls[0].hosts[0]"
      value = "argocd.${var.dns_zone_name}"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.tls[0].secretName"
      value = "argocd-tls"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "${var.cert_manager_issuer_type}-letsencrypt"
    }
  }

  dynamic "set" {
    for_each = var.enable_tls ? [1] : []
    content {
      name  = "server.ingress.annotations.kubernetes\\.io/tls-acme"
      value = "true"
    }
  }

  depends_on = [
    helm_release.nginx_ingress,
    kubernetes_manifest.cluster_issuer,
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
