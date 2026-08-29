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

variable "vnet_address_space" {
  type = list(string)
}

variable "subnet_appgw_prefix" {
  type = string
}

variable "subnet_webapp_prefix" {
  type = string
}

variable "subnet_db_prefix" {
  type = string
}

variable "subnet_bastion_prefix" {
  type = string
}

variable "subnet_pe_prefix" {
  type = string
}
