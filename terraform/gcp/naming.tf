locals {
  cluster_name           = "gke-${var.project_name}-${var.environment}"
  artifact_registry_name = "${var.project_name}-${var.environment}"
  workload_pool          = "${var.project_id}.svc.id.goog"

  common_labels = merge(var.labels, {
    environment = var.environment
    project     = var.project_name
    managed-by  = "terraform"
  })

  short_project = "mmkt"

  naming = {
    gke_cluster         = local.cluster_name
    gke_node_pool       = "primary-node-pool"
    artifact_registry   = local.artifact_registry_name
    artifact_kms_ring   = "${local.short_project}-${var.environment}-ar"
    artifact_kms_key    = "artifact-registry"
    cloud_sql_instance  = "pg-${local.short_project}-${var.environment}"
    cloud_run_keycloak  = "${local.short_project}-keycloak-${var.environment}"
    gke_nodes_sa        = "gke-${local.short_project}-${var.environment}"
    external_secrets_sa = "eso-${var.environment}"
    gitlab_ci_sa        = "gitlab-ci-${var.environment}"
    gitlab_pool          = "gitlab-${var.environment}"
    sql_private_ip_range = "sql-private-${local.short_project}-${var.environment}"
  }
}
