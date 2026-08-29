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

variable "private_endpoints_subnet_id" {
  type = string
}

variable "blob_dns_zone_id" {
  type = string
}
