resource "azurerm_subnet" "bastionhost" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_cidr]
}

resource "azurerm_public_ip" "bastionhost" {
  name                = "pip-bastion-${var.hub_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastionhost" {
  name                = "bastion-${var.hub_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionhost.id
    public_ip_address_id = azurerm_public_ip.bastionhost.id
  }
}

####################################### BASTION DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "bastionhost" {
  resource_id = azurerm_bastion_host.bastionhost.id
}

resource "azurerm_monitor_diagnostic_setting" "bastionhost" {
  name                       = "bastionhostladiagnostics"
  target_resource_id         = azurerm_bastion_host.bastionhost.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.bastionhost.logs

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.bastionhost.metrics

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}

####################################### PIP BASTION DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "pipbastionhost" {
  resource_id = azurerm_public_ip.bastionhost.id
}

resource "azurerm_monitor_diagnostic_setting" "pipbastionhost" {
  name                       = "pipbastionhostladiagnostics"
  target_resource_id         = azurerm_public_ip.bastionhost.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.pipbastionhost.logs

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.pipbastionhost.metrics

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}

variable "log_analytics_workspace_id" {}