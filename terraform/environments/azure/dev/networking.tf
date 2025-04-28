module "networking" {
  source = "../../../modules/azure/networking"

  vnet_name           = "dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_prefixes = [
    { name = "subnet1", prefix = "10.0.1.0/24" },
    { name = "subnet2", prefix = "10.0.2.0/24" }
  ]
}
