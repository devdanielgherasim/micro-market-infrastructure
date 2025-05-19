resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}

resource "azurerm_container_registry" "acr" {

  name                = "acr${var.project_name}${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.acr_sku_name
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "k8s-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "k8s-${var.project_name}-${var.environment}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "ra_acr_k8s" {
  principal_id                     = azurerm_kubernetes_cluster.k8s.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "helm_release" "nginx_ingress" {
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
    azurerm_kubernetes_cluster.k8s
  ]
}

resource "helm_release" "cert_manager" {
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
    azurerm_kubernetes_cluster.k8s,
    helm_release.nginx_ingress
  ]
}

resource "kubernetes_manifest" "cluster_issuer" {
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
    helm_release.cert_manager
  ]
}

resource "helm_release" "argocd" {
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
    value = "argocd.${azurerm_kubernetes_cluster.k8s.name}.${var.location}.azmk8s.io"
  }

  set {
    name  = "server.ingress.tls"
    value = var.enable_tls ? "[{\"hosts\":[\"argocd.${azurerm_kubernetes_cluster.k8s.name}.${var.location}.azmk8s.io\"],\"secretName\":\"argocd-tls\"}]" : "[]"
  }

  set {
    name  = "server.ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = var.enable_tls ? "${var.cert_manager_issuer_type}-letsencrypt" : ""
  }

  set {
    name  = "server.ingress.annotations.kubernetes\\.io/tls-acme"
    value = var.enable_tls ? "true" : "false"
  }

  depends_on = [
    azurerm_kubernetes_cluster.k8s,
    helm_release.nginx_ingress,
    kubernetes_manifest.cluster_issuer
  ]
}

resource "helm_release" "prometheus" {
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
    azurerm_kubernetes_cluster.k8s,
    helm_release.nginx_ingress
  ]
}

resource "helm_release" "grafana" {
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
    value = "grafana.${azurerm_kubernetes_cluster.k8s.name}.${var.location}.azmk8s.io"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = var.enable_tls ? "grafana.${azurerm_kubernetes_cluster.k8s.name}.${var.location}.azmk8s.io" : ""
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = var.enable_tls ? "grafana-tls" : ""
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = var.enable_tls ? "${var.cert_manager_issuer_type}-letsencrypt" : ""
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/tls-acme"
    value = var.enable_tls ? "true" : "false"
  }

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
    azurerm_kubernetes_cluster.k8s,
    helm_release.nginx_ingress,
    helm_release.prometheus,
    kubernetes_manifest.cluster_issuer
  ]
}
