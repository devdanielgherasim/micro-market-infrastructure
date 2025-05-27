# Outputs for Azure infrastructure project
output "resource_group_name" {
  value = module.resource_group.name
}

output "container_registry_id" {
  value = module.container_registry.id
}

output "kubernetes_cluster_name" {
  value = module.kubernetes.name
}

output "kubernetes_resource_group" {
  value = module.kubernetes.resource_group_name
}

output "kubeconfig" {
  value     = module.kubernetes.kubeconfig
  sensitive = true
}

output "dns_zone_name" {
  value = var.dns_zone_name
}
