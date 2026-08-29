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

variable "bastion_subnet_id" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}
