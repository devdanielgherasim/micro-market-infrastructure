location            = "northeurope"
secondary_location  = "swedencentral"
environment    = "staging"
acr_sku_name   = "Basic"
aks_vm_size    = "Standard_F2ams_v6"
node_count     = 2
min_node_count = 2
max_node_count = 2

keycloak_custom_domain_enabled = false

tags = {
  ManagedBy   = "Terraform"
  Environment = "Staging"
  Project     = "Microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
