location       = "germanywestcentral"
environment    = "staging"
acr_sku_name   = "Basic"
aks_vm_size    = "Standard_F2as_v6"
node_count     = 1
min_node_count = 1
max_node_count = 2

tags = {
  ManagedBy   = "Terraform"
  Environment = "Staging"
  Project     = "Microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
