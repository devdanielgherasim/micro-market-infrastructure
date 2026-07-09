# Keycloak on AWS App Runner (ADR-19). Design/IaC-only in this pass: AWS is
# not currently the active cloud (ADR-1, clouds run one at a time), so this
# is not applied or live-validated here - only fmt/validate.
#
# Unlike Azure Container Apps and GCP Cloud Run (both of which can pull an
# arbitrary public image directly), App Runner's `image_repository` only
# supports `ECR` or `ECR_PUBLIC` sources - it cannot pull quay.io/keycloak/
# keycloak directly. This is a real, AWS-specific asymmetry: a one-time image
# mirror (pull quay.io/keycloak/keycloak:26.3.1, retag, push to the ECR repo
# below) is a prerequisite before this service can actually start, and isn't
# something Terraform itself does.
#
# DB connectivity is also asymmetric: RDS here is `publicly_accessible =
# false`, reachable only from the EKS cluster security group (database.tf),
# so App Runner needs its own VPC Connector into the private subnets plus a
# security-group rule extension - unlike Azure/GCP where the DB is already
# public and no networking changes are needed.

resource "aws_ecr_repository" "keycloak" {
  name                 = "${var.project_name}/${var.environment}/keycloak"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_security_group" "apprunner_keycloak" {
  name        = "${local.cluster_name}-apprunner-keycloak"
  description = "Egress-only SG for the App Runner VPC Connector reaching managed PostgreSQL"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Allow outbound to VPC + internet (Secrets Manager, ECR, RDS)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_apprunner_vpc_connector" "keycloak" {
  vpc_connector_name = "${local.cluster_name}-keycloak"
  subnets            = aws_subnet.private[*].id
  security_groups    = [aws_security_group.apprunner_keycloak.id]

  tags = local.tags
}

# RDS's security group only trusted the EKS cluster SG before this; extend it
# so the App Runner connector can reach Postgres now that Keycloak's traffic
# no longer originates from inside the cluster.
resource "aws_security_group_rule" "postgresql_from_apprunner_keycloak" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.postgresql.id
  source_security_group_id = aws_security_group.apprunner_keycloak.id
  description              = "PostgreSQL from the Keycloak App Runner VPC Connector"
}

# --- IAM: access role (ECR pull) vs instance role (runtime Secrets Manager read) ---

data "aws_iam_policy_document" "apprunner_access_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apprunner_keycloak_access" {
  name               = "${local.cluster_name}-apprunner-keycloak-access"
  assume_role_policy = data.aws_iam_policy_document.apprunner_access_assume.json
}

resource "aws_iam_role_policy_attachment" "apprunner_keycloak_access" {
  role       = aws_iam_role.apprunner_keycloak_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

data "aws_iam_policy_document" "apprunner_instance_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apprunner_keycloak_instance" {
  name               = "${local.cluster_name}-apprunner-keycloak-instance"
  assume_role_policy = data.aws_iam_policy_document.apprunner_instance_assume.json
}

# Scoped to exactly the two secrets Keycloak needs - same discipline as
# aws_iam_policy.external_secrets (never "*").
resource "aws_iam_policy" "apprunner_keycloak_instance" {
  name        = "${local.cluster_name}-apprunner-keycloak-instance"
  description = "Read-only access to Keycloak's DB/admin secrets for the App Runner instance"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.platform["keycloak/postgresql"].arn,
          aws_secretsmanager_secret.platform["keycloak/admin"].arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_keycloak_instance" {
  role       = aws_iam_role.apprunner_keycloak_instance.name
  policy_arn = aws_iam_policy.apprunner_keycloak_instance.arn
}

# min_size = max_size = 1: no built-in HA, matching ADR-19's cross-cloud
# decision (Keycloak's JGroups/KUBE_PING clustering has no equivalent here).
resource "aws_apprunner_auto_scaling_configuration_version" "keycloak" {
  auto_scaling_configuration_name = "${local.cluster_name}-keycloak"

  min_size = 1
  max_size = 1

  tags = local.tags
}

resource "aws_apprunner_service" "keycloak" {
  service_name = "${local.cluster_name}-keycloak"

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.keycloak.arn

  source_configuration {
    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_keycloak_access.arn
    }

    image_repository {
      image_repository_type = "ECR"
      image_identifier      = "${aws_ecr_repository.keycloak.repository_url}:26.3.1"

      image_configuration {
        port = "8080"

        # Native JSON-key extraction (`arn:...:secret-id:json-key::`) - unlike
        # Azure Container Apps' Key Vault reference, App Runner can pull a
        # single field out of a JSON secret, so no Terraform-side decode is
        # needed here the way keycloak_paas.tf/azure does.
        runtime_environment_secrets = {
          KC_DB_URL_HOST              = "${aws_secretsmanager_secret.platform["keycloak/postgresql"].arn}:POSTGRES_HOST::"
          KC_DB_URL_PORT              = "${aws_secretsmanager_secret.platform["keycloak/postgresql"].arn}:POSTGRES_PORT::"
          KC_DB_URL_DATABASE          = "${aws_secretsmanager_secret.platform["keycloak/postgresql"].arn}:POSTGRES_DB::"
          KC_DB_USERNAME              = "${aws_secretsmanager_secret.platform["keycloak/postgresql"].arn}:POSTGRES_USER::"
          KC_DB_PASSWORD              = "${aws_secretsmanager_secret.platform["keycloak/postgresql"].arn}:POSTGRES_PASSWORD::"
          KC_BOOTSTRAP_ADMIN_USERNAME = "${aws_secretsmanager_secret.platform["keycloak/admin"].arn}:username::"
          KC_BOOTSTRAP_ADMIN_PASSWORD = "${aws_secretsmanager_secret.platform["keycloak/admin"].arn}:password::"
        }

        # See the Azure leg's keycloak_paas.tf for the same "verify during
        # implementation" caveat on the exact Keycloak 26.x startup flags.
        runtime_environment_variables = {
          KC_DB                 = "postgres"
          KC_HOSTNAME           = "https://auth.danielgherasim.com/auth"
          KC_HOSTNAME_STRICT    = "true"
          KC_HTTP_RELATIVE_PATH = "/auth"
          KC_HTTP_ENABLED       = "true"
          KC_PROXY_HEADERS      = "xforwarded"
          KC_HEALTH_ENABLED     = "true"
          KC_METRICS_ENABLED    = "true"
        }

        start_command = "/opt/keycloak/bin/kc.sh start"
      }
    }
  }

  instance_configuration {
    cpu               = "0.5 vCPU"
    memory            = "1 GB"
    instance_role_arn = aws_iam_role.apprunner_keycloak_instance.arn
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.keycloak.arn
    }
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/auth/health/ready"
  }

  tags = local.tags
}

# Returns certificate_validation_records (CNAME) that must be published via
# the keycloak-dns DNSEndpoint in platform-gitops before App Runner marks the
# domain validated - same two-phase ordering constraint as the Azure leg's
# custom domain binding. Not exercised in this pass since AWS isn't applied.
resource "aws_apprunner_custom_domain_association" "keycloak" {
  domain_name = "auth.danielgherasim.com"
  service_arn = aws_apprunner_service.keycloak.arn
}
