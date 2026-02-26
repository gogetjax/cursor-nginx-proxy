# cjackson-: NGINX VNet and AKS cluster (Kubernetes resources are in root so provider can use this AKS)

locals {
  common_tags = {
    environment = var.environment
    owner_email = var.owner_email
  }
}

resource "azurerm_resource_group" "cjackson_nginx" {
  name     = "${var.resource_prefix}nginx-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "cjackson_nginx" {
  name                = "${var.resource_prefix}nginx-vnet"
  address_space       = var.address_space
  location            = azurerm_resource_group.cjackson_nginx.location
  resource_group_name = azurerm_resource_group.cjackson_nginx.name
  tags                = local.common_tags
}

resource "azurerm_subnet" "cjackson_nginx_aks" {
  name                 = "${var.resource_prefix}nginx-aks-subnet"
  resource_group_name  = azurerm_resource_group.cjackson_nginx.name
  virtual_network_name = azurerm_virtual_network.cjackson_nginx.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_kubernetes_cluster" "cjackson_nginx" {
  name                = "${var.resource_prefix}nginx-aks"
  location            = azurerm_resource_group.cjackson_nginx.location
  resource_group_name = azurerm_resource_group.cjackson_nginx.name
  dns_prefix          = "${var.resource_prefix}nginx"
  kubernetes_version  = var.kubernetes_version
  tags                = local.common_tags

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = "Standard_B2s"
    vnet_subnet_id      = azurerm_subnet.cjackson_nginx_aks.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}
