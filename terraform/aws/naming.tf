locals {
  cluster_name = "eks-${var.project_name}-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })

  short_project = "mmkt"

  naming = {
    eks_cluster = local.cluster_name

    ecr_application = { for name in var.application_names : name => "${var.project_name}/${var.environment}/${name}" }
    ecr_keycloak    = "${var.project_name}/${var.environment}/keycloak"

    rds_identifier        = "${local.cluster_name}-postgresql"
    rds_subnet_group      = "${local.cluster_name}-postgresql"
    postgresql_sg         = "${local.cluster_name}-postgresql"
    postgresql_final_snap = "${local.cluster_name}-postgresql-final"

    apprunner_service             = "${local.short_project}-keycloak-${var.environment}"
    apprunner_vpc_connector       = "${local.short_project}-keycloak-${var.environment}"
    apprunner_auto_scaling_config = "${local.short_project}-keycloak-${var.environment}"
    apprunner_keycloak_sg         = "${local.cluster_name}-apprunner-keycloak"

    iam_role_eks_cluster                  = "${local.cluster_name}-cluster-role"
    iam_role_eks_nodes                    = "${local.cluster_name}-node-role"
    iam_role_vpc_cni                      = "${local.cluster_name}-vpc-cni-role"
    iam_role_ebs_csi                      = "${local.cluster_name}-ebs-csi-role"
    iam_role_aws_load_balancer_controller = "${local.cluster_name}-albc"
    iam_role_external_secrets             = "${local.cluster_name}-external-secrets"
    iam_role_apprunner_keycloak_access    = "${local.cluster_name}-apprunner-keycloak-access"
    iam_role_apprunner_keycloak_instance  = "${local.cluster_name}-apprunner-keycloak-instance"

    iam_policy_aws_load_balancer_controller = "${local.cluster_name}-albc"
    iam_policy_external_secrets             = "${local.cluster_name}-external-secrets"
    iam_policy_apprunner_keycloak_instance  = "${local.cluster_name}-apprunner-keycloak-instance"
  }
}
