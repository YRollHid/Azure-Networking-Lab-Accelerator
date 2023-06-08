
# Virtual Network for Server
# -----------------------

resource "azurerm_virtual_network" "server" {
  name                = "vnet-${var.server_prefix}"
  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = var.location
  address_space       = ["10.8.0.0/20"]
  dns_servers         = null
  tags                = var.tags

}

# Manages an Application Security Group
#
resource "azurerm_application_security_group" "webtier" {
  name                = "WebTier"
  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = var.location

}

resource "azurerm_application_security_group" "datatier" {
  name                = "DataTier"
  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = var.location

}

# SUBNETS on Server Network
# ----------------------

# Server Spoke Subnet
# This subnet is used by App Servers
resource "azurerm_subnet" "app-spoke" {
  name                                           = "AppSubnet"
  resource_group_name                            = azurerm_resource_group.server-spoke-rg.name
  virtual_network_name                           = azurerm_virtual_network.server.name
  address_prefixes                               = ["10.8.0.0/25"]
  enforce_private_link_endpoint_network_policies = false

}

# Server Spoke Subnet
# This subnet is used by Data Servers
resource "azurerm_subnet" "data-spoke" {
  name                                           = "DataSubnet"
  resource_group_name                            = azurerm_resource_group.server-spoke-rg.name
  virtual_network_name                           = azurerm_virtual_network.server.name
  address_prefixes                               = ["10.8.1.0/25"]
  enforce_private_link_endpoint_network_policies = false

}

# Azure Virtual Network peering between Virtual Network Server and Hub
resource "azurerm_virtual_network_peering" "peer_serverSpoke2hub" {
  name                         = "peer-vnet-server-with-hub"
  resource_group_name          = azurerm_resource_group.server-spoke-rg.name
  virtual_network_name         = azurerm_virtual_network.server.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

  depends_on = [azurerm_virtual_network_peering.peer_hub2serverSpoke]
}

# # Create Route Table for Client Spoke
# (All subnets in the client spoke will need to connect to this Route Table)
resource "azurerm_route_table" "server_route_table" {
  name                          = "rt-${var.server_prefix}"
  resource_group_name           = azurerm_resource_group.server-spoke-rg.name
  location                      = var.location
  disable_bgp_route_propagation = false

  route {
    name                   = "AppToInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.7.1.4"
  }

# # Associate Route Table to Server Spoke Subnet
resource "azurerm_subnet_route_table_association" "app_rt_association" {
  subnet_id      = azurerm_subnet.app-spoke.id
  route_table_id = azurerm_route_table.server_route_table.id
}

resource "azurerm_subnet_route_table_association" "data_rt_association" {
  subnet_id      = azurerm_subnet.data-spoke.id
  route_table_id = azurerm_route_table.server_route_table.id
}
####################################### SERVER-SPOKE-VNET DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "server" {
  resource_id = azurerm_virtual_network.server.id
}

 resource "azurerm_monitor_diagnostic_setting" "server" {
   name                       = "serverladiagnostics"
   target_resource_id         = azurerm_virtual_network.server.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  dynamic "log" {
     iterator = entry
     for_each = data.azurerm_monitor_diagnostic_categories.server.logs

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
     for_each = data.azurerm_monitor_diagnostic_categories.server.metrics

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

output "server_vnet_name" {
  value = azurerm_virtual_network.server.name
}

output "server_vnet_id" {
  value = azurerm_virtual_network.server.id
}
