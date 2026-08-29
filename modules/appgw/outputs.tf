output "appgw_id" {
  value = azurerm_application_gateway.main.id
}

output "backend_address_pool_id" {
  value = tolist(azurerm_application_gateway.main.backend_address_pool)[0].id
}

output "public_ip_address" {
  value = azurerm_public_ip.appgw.ip_address
}

output "public_ip_fqdn" {
  value = azurerm_public_ip.appgw.fqdn
}
