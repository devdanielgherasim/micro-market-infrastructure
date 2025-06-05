terraform {
  required_version = "=1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=5.40.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
  token      = var.session_token
}
