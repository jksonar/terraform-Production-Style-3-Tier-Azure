data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

# --- SSH key for the VMSS instances -----------------------------------------
# If the caller didn't supply a public key, generate a keypair so the module
# is usable out of the box. The private key is written to a local file
# (gitignored) rather than left only in state.

resource "tls_private_key" "vmss" {
  count     = var.admin_ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "vmss_private_key" {
  count           = var.admin_ssh_public_key == "" ? 1 : 0
  content         = tls_private_key.vmss[0].private_key_openssh
  filename        = "${path.module}/generated_vmss_ssh_key.pem"
  file_permission = "0600"
}

locals {
  vmss_ssh_public_key = var.admin_ssh_public_key != "" ? var.admin_ssh_public_key : tls_private_key.vmss[0].public_key_openssh
}

resource "random_password" "postgres_admin" {
  length  = 24
  special = true
  # Postgres rejects a handful of punctuation characters in passwords.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# --- Networking --------------------------------------------------------------

module "network" {
  source = "./modules/network"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  vnet_address_space    = var.vnet_address_space
  subnet_appgw_prefix   = var.subnet_appgw_prefix
  subnet_webapp_prefix  = var.subnet_webapp_prefix
  subnet_db_prefix      = var.subnet_db_prefix
  subnet_bastion_prefix = var.subnet_bastion_prefix
  subnet_pe_prefix      = var.subnet_pe_prefix
}

module "dns" {
  source = "./modules/dns"

  resource_group_name = azurerm_resource_group.main.name
  vnet_id             = module.network.vnet_id
  vnet_name           = module.network.vnet_name
  tags                = var.tags
}

# --- Shared services: Key Vault + Storage ------------------------------------

module "keyvault" {
  source = "./modules/keyvault"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  tenant_id                   = data.azurerm_client_config.current.tenant_id
  private_endpoints_subnet_id = module.network.private_endpoints_subnet_id
  vaultcore_dns_zone_id       = module.dns.vaultcore_zone_id
}

resource "azurerm_role_assignment" "current_user_kv_secrets_officer" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC role assignments take a little while to propagate before the data
# plane will honor them.
resource "time_sleep" "wait_for_kv_rbac" {
  depends_on      = [azurerm_role_assignment.current_user_kv_secrets_officer]
  create_duration = "30s"
}

resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres_admin.result
  key_vault_id = module.keyvault.key_vault_id

  depends_on = [time_sleep.wait_for_kv_rbac]
}

resource "azurerm_key_vault_secret" "vmss_ssh_private_key" {
  count        = var.admin_ssh_public_key == "" ? 1 : 0
  name         = "vmss-ssh-private-key"
  value        = tls_private_key.vmss[0].private_key_openssh
  key_vault_id = module.keyvault.key_vault_id

  depends_on = [time_sleep.wait_for_kv_rbac]
}

module "storage" {
  source = "./modules/storage"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  private_endpoints_subnet_id = module.network.private_endpoints_subnet_id
  blob_dns_zone_id            = module.dns.blob_zone_id
}

# --- Database ------------------------------------------------------------

module "database" {
  source = "./modules/database"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  delegated_subnet_id = module.network.db_subnet_id
  private_dns_zone_id = module.dns.postgres_zone_id

  administrator_login    = var.postgres_administrator_login
  administrator_password = random_password.postgres_admin.result
  sku_name               = var.postgres_sku_name
  postgres_version       = var.postgres_version
  storage_mb             = var.postgres_storage_mb
  database_name          = var.postgres_database_name

  depends_on = [module.dns]
}

# --- Management access ---------------------------------------------------

module "bastion" {
  source = "./modules/bastion"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  bastion_subnet_id = module.network.bastion_subnet_id
  sku               = var.bastion_sku
}

# --- Edge: Application Gateway + WAF ---------------------------------------

module "appgw" {
  source = "./modules/appgw"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  appgw_subnet_id = module.network.appgw_subnet_id
  sku_name        = var.appgw_sku_name
  min_capacity    = var.appgw_min_capacity
  max_capacity    = var.appgw_max_capacity
}

# --- Web/app tier: VMSS ------------------------------------------------------

module "vmss" {
  source = "./modules/vmss"

  prefix              = var.prefix
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  webapp_subnet_id        = module.network.webapp_subnet_id
  backend_address_pool_id = module.appgw.backend_address_pool_id
  admin_username          = var.admin_username
  admin_ssh_public_key    = local.vmss_ssh_public_key
  sku                     = var.vmss_sku
  instance_count          = var.vmss_instance_count
  min_instances           = var.vmss_min_instances
  max_instances           = var.vmss_max_instances
}
