output "postgres_zone_id" {
  value = azurerm_private_dns_zone.postgres.id
}

output "vaultcore_zone_id" {
  value = azurerm_private_dns_zone.vaultcore.id
}

output "blob_zone_id" {
  value = azurerm_private_dns_zone.blob.id
}

output "postgres_zone_link_id" {
  value = azurerm_private_dns_zone_virtual_network_link.postgres.id
}
