module "aws_registry" {
  source          = "../../modules/aws_registry"
  name            = "dev-ecr-repo"
  environment     = "dev"
  aws_role_name   = var.aws_role_name
}
