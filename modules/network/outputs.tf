output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "vnet_name" {
  value = azurerm_virtual_network.main.name
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "webapp_subnet_id" {
  value = azurerm_subnet.webapp.id
}

output "db_subnet_id" {
  value = azurerm_subnet.db.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion.id
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}
