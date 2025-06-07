resource "kubernetes_namespace_v1" "keycloak" {
  metadata {
    name = "keycloak"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
      "app.kubernetes.io/part-of"    = "keycloak"
    }
  }
}

resource "random_password" "keycloak_admin_password" {
  length  = 16
  special = false
}

resource "helm_release" "keycloak" {
  name             = "keycloak"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "keycloak"
  version          = "15.1.3"
  namespace        = kubernetes_namespace_v1.keycloak.metadata[0].name
  create_namespace = false
  dependency_update = true
  lint              = true
  timeout           = 600
  depends_on        = [helm_release.cert_manager, helm_release.nginx-ingress]

  values = [
    <<-EOT
    fullnameOverride: keycloak

    auth:
      adminUser: admin
      adminPassword: ${random_password.keycloak_admin_password.result}

    extraEnvVars:
      - name: KC_PROXY
        value: edge
      - name: KC_HOSTNAME_STRICT
        value: "false"
      - name: KC_HOSTNAME_STRICT_HTTPS
        value: "false"
      - name: KC_HTTP_RELATIVE_PATH
        value: "/keycloak"
      - name: KEYCLOAK_EXTRA_ARGS
        value: "-Dkeycloak.import=/opt/keycloak/data/import/realm.json"

    extraVolumes:
      - name: realm-config
        configMap:
          name: keycloak-realm-config

    extraVolumeMounts:
      - name: realm-config
        mountPath: /opt/keycloak/data/import/
        readOnly: true

    service:
      type: ClusterIP

    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: ${var.cluster_issuer}
        nginx.ingress.kubernetes.io/proxy-body-size: 20m
        acme.cert-manager.io/http01-edit-in-place: "true"
        nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      rules:
        - host: ${local.current_domain}
          paths:
            - path: /keycloak
              pathType: Prefix
      tls:
        - hosts:
            - ${local.current_domain}
          secretName: tls-secret-keycloak

    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
    EOT
  ]

  set_sensitive {
    name  = "auth.adminPassword"
    value = random_password.keycloak_admin_password.result
  }
}

resource "kubernetes_config_map_v1" "keycloak_realm_config" {
  metadata {
    name      = "keycloak-realm-config"
    namespace = kubernetes_namespace_v1.keycloak.metadata[0].name
  }

  data = {
    "realm.json" = jsonencode({
      realm = var.project_name
      enabled = true
      displayName = var.project_name
      displayNameHtml = "<div class=\"kc-logo-text\"><span>${var.project_name}</span></div>"
      sslRequired = "external"
      registrationAllowed = false
      loginWithEmailAllowed = true
      duplicateEmailsAllowed = false
      resetPasswordAllowed = true
      editUsernameAllowed = false
      bruteForceProtected = true
    })
  }
}

output "keycloak_url" {
  description = "Keycloak URL"
  value       = "https://${local.current_domain}/keycloak"
}

output "keycloak_admin_username" {
  description = "Keycloak admin username"
  value       = "admin"
}

output "keycloak_admin_password" {
  description = "Keycloak admin password"
  value       = random_password.keycloak_admin_password.result
  sensitive   = true
}
