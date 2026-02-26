# cjackson-: Producer VNet (separate from NGINX); Producer runs elsewhere and connects via public internet to NGINX

resource "azurerm_resource_group" "cjackson_producer" {
  name     = "${var.resource_prefix}producer-rg"
  location = var.location
}

resource "azurerm_virtual_network" "cjackson_producer" {
  name                = "${var.resource_prefix}producer-vnet"
  address_space       = var.address_space
  location            = azurerm_resource_group.cjackson_producer.location
  resource_group_name = azurerm_resource_group.cjackson_producer.name
}

resource "azurerm_subnet" "cjackson_producer" {
  name                 = "${var.resource_prefix}producer-subnet"
  resource_group_name  = azurerm_resource_group.cjackson_producer.name
  virtual_network_name = azurerm_virtual_network.cjackson_producer.name
  address_prefixes     = [var.subnet_prefix]
}

resource "azurerm_network_security_group" "cjackson_producer" {
  name                = "${var.resource_prefix}producer-nsg"
  location            = azurerm_resource_group.cjackson_producer.location
  resource_group_name = azurerm_resource_group.cjackson_producer.name
}
