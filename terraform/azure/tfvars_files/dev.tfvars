location       = "germanywestcentral"
environment    = "dev"
acr_sku_name   = "Basic"
aks_vm_size    = "Standard_F2ams_v6"
node_count     = 2
min_node_count = 2
max_node_count = 2

# Free Azure accounts here have a 4 regional vCPU quota. Keep dev capped at
# 2 x 2-vCPU nodes and disable Azure Policy/Gatekeeper to leave room for the
# GitOps platform and app demo workloads.
azure_policy_enabled = false

github_repos = [
  "devdanielgherasim/micro-market-audit",
  "devdanielgherasim/micro-market-catalog",
  "devdanielgherasim/micro-market-orders",
  "devdanielgherasim/micro-market-frontend",
]

tags = {
  ManagedBy   = "Terraform"
  Environment = "Development"
  Project     = "Microservices"
  Owner       = "adriangherasim"
  CostCenter  = "adriangherasim1@gmail.com"
}
