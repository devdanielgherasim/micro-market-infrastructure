output "aws_registry_url" {
  value = module.aws_registry.repository_url
}

output "gcp_registry_url" {
  value = module.gcp_registry.repository_url
}

output "azure_registry_url" {
  value = module.azure_registry.registry_url
}
