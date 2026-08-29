resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_key_vault" "main" {
  # Globally unique, max 24 chars.
  name                = substr("kv-${var.prefix}-${var.environment}-${random_string.kv_suffix.result}", 0, 24)
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"
  tags                = var.tags

  rbac_authorization_enabled = true
  purge_protection_enabled   = false

  # Public network access is left enabled so Terraform (run from outside the
  # VNet) can write secrets via the data plane. The private endpoint below
  # gives in-VNet consumers (VMSS, Bastion-attached admins) a private path;
  # for a stricter posture, disable public access and run Terraform from a
  # host inside the VNet instead.
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_private_endpoint" "kv" {
  name                = "${var.prefix}-${var.environment}-pe-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.vaultcore_dns_zone_id]
  }
}
