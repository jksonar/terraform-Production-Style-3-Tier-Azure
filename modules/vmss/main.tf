resource "azurerm_linux_virtual_machine_scale_set" "webapp" {
  name                = "${var.prefix}-${var.environment}-vmss-webapp"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku       = var.sku
  instances = var.instance_count

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))

  upgrade_mode = "Automatic"

  network_interface {
    name    = "nic-webapp"
    primary = true

    ip_configuration {
      name                                         = "ipconfig-webapp"
      primary                                      = true
      subnet_id                                    = var.webapp_subnet_id
      application_gateway_backend_address_pool_ids = [var.backend_address_pool_id]
    }
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

resource "azurerm_monitor_autoscale_setting" "webapp" {
  name                = "${var.prefix}-${var.environment}-autoscale-webapp"
  location            = var.location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.webapp.id
  tags                = var.tags

  profile {
    name = "cpu-based"

    capacity {
      default = var.instance_count
      minimum = var.min_instances
      maximum = var.max_instances
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.webapp.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.webapp.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}
