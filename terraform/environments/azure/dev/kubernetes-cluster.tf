module "aks" {
  source = "../../../modules/azure/kubernetes-cluster"

  name                = "dev-aks-cluster"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "devaks"
  node_count          = 2
  vm_size             = "Standard_DS2_v2"
  tags                = var.tags
}
