mock_provider "aws" {}
mock_provider "tls" {}

override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "123456789012"
  }
}

override_data {
  target = data.aws_availability_zones.available
  values = {
    names = ["eu-central-1a", "eu-central-1b"]
  }
}

override_data {
  target = data.tls_certificate.eks_oidc
  values = {
    certificates = [{
      sha1_fingerprint = "0000000000000000000000000000000000000000"
    }]
  }
}

override_data {
  target = data.aws_eks_addon_version.vpc_cni
  values = {
    version = "v1.20.0-eksbuild.1"
  }
}

override_data {
  target = data.aws_eks_addon_version.kube_proxy
  values = {
    version = "v1.36.0-eksbuild.1"
  }
}

override_data {
  target = data.aws_eks_addon_version.coredns
  values = {
    version = "v1.12.0-eksbuild.1"
  }
}

override_data {
  target = data.aws_eks_addon_version.ebs_csi_driver
  values = {
    version = "v1.48.0-eksbuild.1"
  }
}

override_data {
  target = data.aws_iam_policy_document.eks_secrets_key
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.ecr_key
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.vpc_flow_logs_assume
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.vpc_flow_logs_publish
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.eks_cluster_assume
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.eks_nodes_assume
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.vpc_cni_assume
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.ebs_csi_assume
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.apprunner_access_assume
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.apprunner_instance_assume
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

override_data {
  target = data.aws_iam_policy_document.irsa_assume_role
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Resource\":\"*\"}]}"
  }
}

run "eks_cluster_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.eks_cluster) >= 1 && length(local.naming.eks_cluster) <= 100
    error_message = "eks_cluster name must be 1-100 chars"
  }

  assert {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", local.naming.eks_cluster))
    error_message = "eks_cluster name must start alphanumeric and contain only alphanumerics, underscores, or hyphens"
  }
}

run "ecr_repository_names" {
  command = plan

  assert {
    condition = alltrue(concat(
      [for name in values(local.naming.ecr_application) : length(name) >= 2 && length(name) <= 256],
      [length(local.naming.ecr_keycloak) >= 2 && length(local.naming.ecr_keycloak) <= 256]
    ))
    error_message = "ECR repository names must be 2-256 chars"
  }

  assert {
    condition = alltrue(concat(
      [for name in values(local.naming.ecr_application) : can(regex("^[a-z0-9]+([._/-][a-z0-9]+)*$", name))],
      [can(regex("^[a-z0-9]+([._/-][a-z0-9]+)*$", local.naming.ecr_keycloak))]
    ))
    error_message = "ECR repository names must use lowercase path components separated by ., _, -, or /"
  }
}

run "rds_identifier_length_and_charset" {
  command = plan

  assert {
    condition     = length(local.naming.rds_identifier) >= 1 && length(local.naming.rds_identifier) <= 63
    error_message = "RDS identifier must be 1-63 chars"
  }

  assert {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", local.naming.rds_identifier))
    error_message = "RDS identifier must start with a letter, end alphanumeric, and contain only alphanumerics or hyphens"
  }

  assert {
    condition     = !can(regex("--", local.naming.rds_identifier))
    error_message = "RDS identifier must not contain consecutive hyphens"
  }
}

run "iam_role_names" {
  command = plan

  assert {
    condition = alltrue([
      for name in [
        local.naming.iam_role_eks_cluster,
        local.naming.iam_role_eks_nodes,
        local.naming.iam_role_vpc_cni,
        local.naming.iam_role_ebs_csi,
        local.naming.iam_role_aws_load_balancer_controller,
        local.naming.iam_role_external_secrets,
        local.naming.iam_role_apprunner_keycloak_access,
        local.naming.iam_role_apprunner_keycloak_instance,
      ] : length(name) >= 1 && length(name) <= 64
    ])
    error_message = "IAM role names must be 1-64 chars"
  }

  assert {
    condition = alltrue([
      for name in [
        local.naming.iam_role_eks_cluster,
        local.naming.iam_role_eks_nodes,
        local.naming.iam_role_vpc_cni,
        local.naming.iam_role_ebs_csi,
        local.naming.iam_role_aws_load_balancer_controller,
        local.naming.iam_role_external_secrets,
        local.naming.iam_role_apprunner_keycloak_access,
        local.naming.iam_role_apprunner_keycloak_instance,
      ] : can(regex("^[A-Za-z0-9+=,.@_-]+$", name))
    ])
    error_message = "IAM role names must contain only alphanumerics and +=,.@_-"
  }
}

run "apprunner_names" {
  command = plan

  assert {
    condition     = length(local.naming.apprunner_service) >= 4 && length(local.naming.apprunner_service) <= 40
    error_message = "App Runner service name must be 4-40 chars"
  }

  assert {
    condition     = length(local.naming.apprunner_vpc_connector) >= 4 && length(local.naming.apprunner_vpc_connector) <= 40
    error_message = "App Runner VPC connector name must be 4-40 chars"
  }

  assert {
    condition     = length(local.naming.apprunner_auto_scaling_config) >= 4 && length(local.naming.apprunner_auto_scaling_config) <= 32
    error_message = "App Runner auto scaling configuration name must be 4-32 chars"
  }

  assert {
    condition = alltrue([
      for name in [
        local.naming.apprunner_service,
        local.naming.apprunner_vpc_connector,
        local.naming.apprunner_auto_scaling_config,
      ] : can(regex("^[A-Za-z0-9][A-Za-z0-9_-]*$", name))
    ])
    error_message = "App Runner names must start alphanumeric and contain only alphanumerics, underscores, or hyphens"
  }
}
