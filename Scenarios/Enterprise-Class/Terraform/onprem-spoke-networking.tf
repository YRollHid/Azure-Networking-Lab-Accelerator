
# Virtual Network for OnPrem
# -----------------------

resource "azurerm_virtual_network" "onprem" {
  name                = "vnet-${var.onprem_prefix}"
  resource_group_name = azurerm_resource_group.onprem-spoke-rg.name
  location            = var.onprem_location
  address_space       = ["192.168.0.0/16"]
  dns_servers         = null
  tags                = var.tags

}

# SUBNETS on OnPrem Network
# ----------------------

# OnPrem Spoke Subnet
# This subnet is used by OnPrem VM
resource "azurerm_subnet" "onprem-spoke" {
  name                                           = "OnPremSpokeSubnet"
  resource_group_name                            = azurerm_resource_group.onprem-spoke-rg.name
  virtual_network_name                           = azurerm_virtual_network.onprem.name
  address_prefixes                               = ["192.168.0.0/24"]
  enforce_private_link_endpoint_network_policies = false

}

# Gateway Subnet 
# (Additional subnet for Gateway, without NSG as per requirements)
resource "azurerm_subnet" "onprem-gateway" {
  name                                           = "GatewaySubnet"
  resource_group_name                            = azurerm_resource_group.onprem-spoke-rg.name
  virtual_network_name                           = azurerm_virtual_network.onprem.name
  address_prefixes                               = ["192.168.1.0/27"]
  enforce_private_link_endpoint_network_policies = false

}

# Azure Virtual Network peering between Virtual Network onprem and Hub
# resource "azurerm_virtual_network_peering" "peer_onpremSpoke2hub" {
#   name                         = "peer-vnet-onprem-with-hub"
#   resource_group_name          = azurerm_resource_group.onprem-spoke-rg.name
#   virtual_network_name         = azurerm_virtual_network.onprem.name
#   remote_virtual_network_id    = azurerm_virtual_network.hub.id
#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = true

#   depends_on = [azurerm_virtual_network_peering.peer_hub2clinetSpoke]
# }

# # Create Route Table for onprem Spoke
# (All subnets in the onprem spoke will need to connect to this Route Table)
# resource "azurerm_route_table" "onprem_route_table" {
#   name                          = "rt-${var.onprem_prefix}"
#   resource_group_name           = azurerm_resource_group.onprem-spoke-rg.name
#   location                      = var.location
#   disable_bgp_route_propagation = false

#   route {
#     name                   = "route_to_firewall"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = "10.0.1.4"
#   }
# }

# # Associate Route Table to onprem Spoke Subnet
# resource "azurerm_subnet_route_table_association" "onprem_rt_association" {
#   subnet_id      = azurerm_subnet.onprem-spoke.id
#   route_table_id = azurerm_route_table.onprem_route_table.id
# }

####################################### onprem-SPOKE-VNET DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "onprem" {
  resource_id = azurerm_virtual_network.onprem.id
}

resource "azurerm_monitor_diagnostic_setting" "onprem" {
  name                       = "onpremladiagnostics"
  target_resource_id         = azurerm_virtual_network.onprem.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.onprem.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.onprem.metrics

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

#############
## OUTPUTS ##
#############
# These outputs are used by later deployments

output "onprem_vnet_name" {
  value = azurerm_virtual_network.onprem.name
}

output "onprem_vnet_id" {
  value = azurerm_virtual_network.onprem.id
}
