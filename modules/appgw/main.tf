locals {
  appgw_name              = "${var.prefix}-${var.environment}-appgw"
  frontend_port_name      = "feport-80"
  frontend_ip_config_name = "feip-public"
  backend_pool_name       = "backend-webapp"
  http_setting_name       = "http-setting-80"
  listener_name           = "listener-http-80"
  request_routing_rule    = "rule-http-80"
  probe_name              = "probe-webapp"
}

resource "azurerm_public_ip" "appgw" {
  name                = "${var.prefix}-${var.environment}-pip-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "${var.prefix}-${var.environment}-wafpolicy"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "main" {
  name                = local.appgw_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  firewall_policy_id = azurerm_web_application_firewall_policy.main.id

  sku {
    name = var.sku_name
    tier = var.sku_name
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = var.appgw_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  backend_address_pool {
    name = local.backend_pool_name
  }

  probe {
    name                                      = local.probe_name
    protocol                                  = "Http"
    path                                      = "/"
    pick_host_name_from_backend_http_settings = true
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = local.probe_name
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_config_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  lifecycle {
    ignore_changes = [
      # The VMSS module attaches instances to this pool out-of-band via the
      # pool's id; avoid fighting over the (empty-looking) pool definition.
      backend_address_pool,
    ]
  }
}
