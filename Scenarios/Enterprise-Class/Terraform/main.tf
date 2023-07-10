# Data From Existing Infrastructure
#############
# RESOURCES #
#############

# Resource Group for Hub
# ----------------------

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.hub_prefix}"
  location = var.location
}

# Resource Group for OnPrem Spoke VNET
# ----------------------

resource "azurerm_resource_group" "onprem-spoke-rg" {
  name     = "rg-${var.onprem_prefix}"
  location = var.onprem_location
}

# Resource Group for Server Spoke VNET
# ----------------------

resource "azurerm_resource_group" "server-spoke-rg" {
  name     = "rg-${var.server_prefix}"
  location = var.location
}

# Resource Group for Monitoring via Network Watcher
# ----------------------

resource "azurerm_resource_group" "monitoring-rg" {
  name     = "rg-${var.monitoring_prefix}"
  location = var.location
}


#############
## OUTPUTS ##
#############
# These outputs are used by later deployments

output "hub_rg_location" {
  value = azurerm_resource_group.rg.location
}

output "hub_rg_name" {
  value = azurerm_resource_group.rg.name
}



