output "project_name" {
  value       = var.project_name
  description = "The name of the project"
}

output "domain" {
  value       = local.current_domain
  description = "The domain name for the cluster"
}