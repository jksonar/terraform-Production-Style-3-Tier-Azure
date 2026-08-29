variable "prefix" {
  description = "Short name prepended to all resources, e.g. 'az3t'."
  type        = string
  default     = "az3t"
}

variable "environment" {
  description = "Environment name, e.g. 'prod', 'dev'."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    project   = "3-tier-azure"
    managedBy = "terraform"
  }
}

# --- Networking ---------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the VNet."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_appgw_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_webapp_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_db_prefix" {
  type    = string
  default = "10.0.3.0/24"
}

variable "subnet_bastion_prefix" {
  type    = string
  default = "10.0.4.0/24"
}

variable "subnet_pe_prefix" {
  type    = string
  default = "10.0.5.0/24"
}

# --- VMSS (web/app tier) -------------------------------------------------

variable "admin_username" {
  description = "Admin username for the VMSS Linux instances."
  type        = string
  default     = "azureadmin"
}

variable "admin_ssh_public_key" {
  description = "SSH public key content used to log in to the VMSS instances via Bastion. Leave blank to auto-generate one (private key is written locally and NOT stored in state-safe form) - for real use, supply your own public key."
  type        = string
  default     = ""
}

variable "vmss_sku" {
  description = "VM size for each VMSS instance."
  type        = string
  default     = "Standard_B2s"
}

variable "vmss_instance_count" {
  description = "Initial/default number of VMSS instances."
  type        = number
  default     = 2
}

variable "vmss_min_instances" {
  type    = number
  default = 2
}

variable "vmss_max_instances" {
  type    = number
  default = 5
}

# --- Database -------------------------------------------------------------

variable "postgres_sku_name" {
  description = "SKU for the PostgreSQL Flexible Server."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_version" {
  type    = string
  default = "16"
}

variable "postgres_storage_mb" {
  type    = number
  default = 32768
}

variable "postgres_administrator_login" {
  type    = string
  default = "pgadmin"
}

variable "postgres_database_name" {
  type    = string
  default = "appdb"
}

# --- Bastion ---------------------------------------------------------------

variable "bastion_sku" {
  description = "Bastion SKU: Basic or Standard."
  type        = string
  default     = "Basic"
}

# --- Application Gateway ----------------------------------------------------

variable "appgw_sku_name" {
  type    = string
  default = "WAF_v2"
}

variable "appgw_capacity" {
  description = "Fixed capacity when autoscaling is disabled (unused when min/max are set)."
  type        = number
  default     = 2
}

variable "appgw_min_capacity" {
  type    = number
  default = 1
}

variable "appgw_max_capacity" {
  type    = number
  default = 3
}
