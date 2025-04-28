module "aws_registry" {
  source        = "../../modules/aws_registry"
  name          = "dev-ecr-repo"
  environment   = var.environment
  aws_role_name = var.aws_role_name
}

module "gcp_registry" {
  source                = "../../modules/gcp_registry"
  name                  = "dev-gcp-repo"
  environment           = var.environment
  region                = var.gcp_region
  project_id            = var.gcp_project_id
  service_account_email = var.gcp_service_account_email
}

module "azure_registry" {
  source          = "../../modules/azure_registry"
  name            = "devacrrepo"
  resource_group  = var.azure_resource_group
  location        = var.azure_location
  environment     = var.environment
  principal_id    = var.azure_principal_id
}
