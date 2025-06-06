locals {
  argocd_domain = local.current_domain
}

resource "random_password" "argo_password" {
  length  = 16
  special = true
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
  depends_on       = [helm_release.cert_manager]
  create_namespace = false
  dependency_update = true
  lint              = true
  values            = [file("${path.root}/configs/argocd_config.yaml")]
  timeout           = 600

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = random_password.argo_password.result
  }

  set {
    name  = "global.domain"
    value = local.argocd_domain
  }

  set {
    name  = "configs.cm.ui\\.bannercontent"
    value = "Hi! This is ArgoCD on ${var.environment}"
  }

  set {
    name  = "configs.cm.url"
    value = "https://${local.argocd_domain}/argocd"
  }

  set {
    name  = "configs.cm.statusbadge\\.url"
    value = "https://${local.argocd_domain}/argocd"
  }

  set {
    name  = "configs.cm.kustomize\\.buildOptions"
    value = "--enable-helm --load-restrictor LoadRestrictionsNone"
  }

  set_sensitive {
    name  = "configs.credentialTemplates.https-creds.password"
    value = "glpat-s7pTFTXzVbi8vBHhbomj" // TODO DE PUS IN SECRETS
  }
  set {
    name  = "configs.credentialTemplates.https-creds.username"
    value = "adriangherasim1@gmail.com"
  }
  set {
    name  = "configs.credentialTemplates.https-creds.url"
    value = "https://gitlab.com/microservices1691715"
  }
}
