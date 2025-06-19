location       = "westeurope"
environment    = "prod"
acr_sku_name   = "Basic"
aks_vm_size    = "Standard_F4s_v2"
node_count     = 1
min_node_count = 1
max_node_count = 2

tags = {
  ManagedBy   = "Terraform"
  Environment = "Production"
  Project     = "Microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
