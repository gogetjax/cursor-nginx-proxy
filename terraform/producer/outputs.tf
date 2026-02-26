# cjackson-: Producer VNet outputs

output "resource_group_name" {
  value = azurerm_resource_group.cjackson_producer.name
}

output "vnet_id" {
  value = azurerm_virtual_network.cjackson_producer.id
}

output "subnet_id" {
  value = azurerm_subnet.cjackson_producer.id
}
