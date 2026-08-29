output "bastion_id" {
  value = azurerm_bastion_host.main.id
}

output "bastion_fqdn" {
  value = azurerm_bastion_host.main.dns_name
}
