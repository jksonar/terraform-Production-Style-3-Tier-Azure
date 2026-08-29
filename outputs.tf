output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "appgw_public_ip" {
  description = "Public entry point for the application."
  value       = module.appgw.public_ip_address
}

output "bastion_fqdn" {
  value = module.bastion.bastion_fqdn
}

output "postgres_server_fqdn" {
  value = module.database.server_fqdn
}

output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "vmss_ssh_private_key_path" {
  description = "Local path to the generated SSH private key, only set when admin_ssh_public_key was left blank."
  value       = var.admin_ssh_public_key == "" ? local_sensitive_file.vmss_private_key[0].filename : null
}
