
# Azure Firewall 
# --------------
# Firewall Rules created via Module

resource "azurerm_firewall" "firewall" {
  name                = "fw-${var.hub_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  firewall_policy_id  = module.firewall_rules_vm.fw_policy_id
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-${var.hub_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

module "firewall_rules_vm" {
  source = "./modules/compute-fw-rules"

  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  hub_prefix            = var.hub_prefix
  ipgrp_deny_hub_lab_id = azurerm_ip_group.ipgrp_deny.id

}

####################################### FIREWALL DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "firewall" {
  resource_id = azurerm_firewall.firewall.id
}

 resource "azurerm_monitor_diagnostic_setting" "firewall" {
   name                       = "fwladiagnostics"
   target_resource_id         = azurerm_firewall.firewall.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  dynamic "log" {
     iterator = entry
     for_each = data.azurerm_monitor_diagnostic_categories.firewall.logs

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
     for_each = data.azurerm_monitor_diagnostic_categories.firewall.metrics

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

####################################### PIP FIREWALL DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "pip-fw" {
  resource_id = azurerm_public_ip.firewall.id
}

 resource "azurerm_monitor_diagnostic_setting" "pip-fw" {
   name                       = "pipfwladiagnostics"
   target_resource_id         = azurerm_public_ip.firewall.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  dynamic "log" {
     iterator = entry
     for_each = data.azurerm_monitor_diagnostic_categories.pip-fw.logs

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
     for_each = data.azurerm_monitor_diagnostic_categories.pip-fw.metrics

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