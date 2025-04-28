module "iam" {
  source = "../../../modules/azure/iam"

  principal_id         = "<YOUR-PRINCIPAL-ID>"
  role_definition_name = "Contributor"
  scope                = "<SCOPE-RESOURCE-ID>"
}
