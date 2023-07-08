####################################
# These resources will use onprem subnet for user connectivity
# to the VMs with the Bastion Service.
####################################

resource "azurerm_network_security_group" "onprem-nsg" {
  name                = "${azurerm_virtual_network.onprem.name}-${azurerm_subnet.onprem-spoke.name}-nsg"
  resource_group_name = azurerm_resource_group.onprem-spoke-rg.name
  location            = azurerm_resource_group.onprem-spoke-rg.location

}

resource "azurerm_subnet_network_security_group_association" "onprem-subnet" {
  subnet_id                 = azurerm_subnet.onprem-spoke.id
  network_security_group_id = azurerm_network_security_group.onprem-nsg.id
}

# Kali Client VM

module "create_kaliclient" {
  source = "./modules/compute/kali"

  resource_group_name = azurerm_resource_group.onprem-spoke-rg.name
  location            = azurerm_resource_group.onprem-spoke-rg.location
  vnet_subnet_id      = azurerm_subnet.onprem-spoke.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  server_name    = "CLIENT-LINUX"
  admin_username = var.client_admin_username
  admin_password = var.client_admin_password

}

# Win10 Client VM

module "create_win10client" {
  source = "./modules/compute/win10"

  resource_group_name = azurerm_resource_group.onprem-spoke-rg.name
  location            = azurerm_resource_group.onprem-spoke-rg.location
  vnet_subnet_id      = azurerm_subnet.onprem-spoke.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  server_name    = "CLIENT-WIN10"
  admin_username = var.client_admin_username
  admin_password = var.client_admin_password

}

####################################### ONPREM-SPOKE-NSG DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "onprem-nsg" {
  resource_id = azurerm_network_security_group.onprem-nsg.id
}

 resource "azurerm_monitor_diagnostic_setting" "onprem-nsg" {
   name                       = "onprem-nsgladiagnostics"
   target_resource_id         = azurerm_network_security_group.onprem-nsg.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  dynamic "log" {
     iterator = entry
     for_each = data.azurerm_monitor_diagnostic_categories.onprem-nsg.logs

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
     for_each = data.azurerm_monitor_diagnostic_categories.onprem-nsg.metrics

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

#######################
# SENSITIVE VARIABLES #
#######################

variable "client_admin_password" {
  default = "changeme"
}

variable "client_admin_username" {
  default = "sysadmin"
}
