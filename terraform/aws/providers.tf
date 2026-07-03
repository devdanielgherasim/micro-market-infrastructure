terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Bucket/region are provided at init time via -backend-config (see ../apply.sh).
  # State locking uses S3 native lockfiles (use_lockfile) - no DynamoDB table needed.
  backend "s3" {}
}

# Credentials are supplied exclusively by the environment
# (AWS_PROFILE or AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN).
# Never hardcode credentials in Terraform files or scripts.
provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}
