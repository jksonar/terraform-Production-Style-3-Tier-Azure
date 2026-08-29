variable "prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "tenant_id" {
  type = string
}

variable "private_endpoints_subnet_id" {
  type = string
}

variable "vaultcore_dns_zone_id" {
  type = string
}
