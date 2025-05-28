resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_container_registry" "this" {
  name                = "acr${var.project_name}${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.acr_sku_name
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_public_ip" "this" {
  name                = "aks-lb-ip-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.project_name
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "k8s-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "k8s-${var.project_name}-${var.environment}"
  kubernetes_version  = "1.32.4"
  node_resource_group = "rg-${var.project_name}-${var.environment}"

  default_node_pool {
    name                        = "default"
    node_count                  = var.node_count
    vm_size                     = var.aks_vm_size
    os_disk_size_gb             = 30
    node_public_ip_prefix_id    = azurerm_public_ip.this.public_ip_prefix_id
    node_public_ip_enabled      = true
    temporary_name_for_rotation = "tempnode"
    max_pods                    = 90
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    load_balancer_profile {
      outbound_ip_address_ids = [azurerm_public_ip.this.id]
    }
  }

  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
  depends_on = [azurerm_container_registry.this]
}


resource "azurerm_role_assignment" "this" {
  principal_id                     = azurerm_kubernetes_cluster.this.identity[0].principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.this.id
  skip_service_principal_aad_check = true
}

locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}
