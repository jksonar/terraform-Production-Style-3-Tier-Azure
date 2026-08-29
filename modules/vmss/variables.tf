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

variable "webapp_subnet_id" {
  type = string
}

variable "backend_address_pool_id" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_ssh_public_key" {
  type = string
}

variable "sku" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "min_instances" {
  type = number
}

variable "max_instances" {
  type = number
}
