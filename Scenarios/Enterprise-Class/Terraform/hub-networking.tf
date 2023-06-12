
# Virtual Network for Hub
# -----------------------

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.hub_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["10.7.0.0/20"]
  dns_servers         = null
  tags                = var.tags

}

# SUBNETS on Hub Network
# ----------------------

# Gateway Subnet 
# (Additional subnet for Gateway, without NSG as per requirements)
resource "azurerm_subnet" "hub-gateway" {
  name                                           = "GatewaySubnet"
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.hub.name
  address_prefixes                               = ["10.7.0.0/27"]
  enforce_private_link_endpoint_network_policies = false

}

# Firewall Subnet
# (Additional subnet for Azure Firewall, without NSG as per Firewall requirements)
resource "azurerm_subnet" "firewall" {
  name                                           = "AzureFirewallSubnet"
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.hub.name
  address_prefixes                               = ["10.7.1.0/24"]
  enforce_private_link_endpoint_network_policies = false

}

# Management Subnet
# (Additional subnet for Management)
resource "azurerm_subnet" "management" {
  name                                           = "Management"
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.hub.name
  address_prefixes                               = ["10.7.2.0/25"]
  enforce_private_link_endpoint_network_policies = false

}

resource "azurerm_public_ip" "pip1-hub-vpngw" {
  name                                           = "pip1-vpngw-${var.hub_prefix}"
  resource_group_name                            = azurerm_resource_group.rg.name
  location                                       = var.location
  allocation_method                              = "Dynamic"
}

resource "azurerm_public_ip" "pip2-hub-vpngw" {
  name                                           = "pip2-vpngw-${var.hub_prefix}"
  resource_group_name                            = azurerm_resource_group.rg.name
  location                                       = var.location
  allocation_method                              = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "hub-vpngw" {
  name                                           = "vpngw-${var.hub_prefix}"
  resource_group_name                            = azurerm_resource_group.rg.name
  location                                       = var.location

  type                                           = "Vpn"
  vpn_type                                       = "RouteBased"

  active_active                                  = var.active_active
  enable_bgp                                     = false
  sku                                            = "VpnGw1"

  ip_configuration {
    name                                         = "vnetGatewayConfig"
    public_ip_address_id                         = azurerm_public_ip.pip1-hub-vpngw.id
    private_ip_address_allocation                = "Dynamic"
    subnet_id                                    = azurerm_subnet.hub-gateway.id
  }

 dynamic "ip_configuration" {
    for_each = var.active_active ? [true] : []
    content {
      name                          = "vnetGatewayConfigSecondary"
      public_ip_address_id          = azurerm_public_ip.pip2-hub-vpngw.id
      private_ip_address_allocation = "Dynamic"
      subnet_id                     = azurerm_subnet.hub-gateway.id
    }
  }
  
}

resource "azurerm_virtual_network_gateway_connection" "eastus2_to_westus3" {
  name                                           = "con-onprem-${var.hub_prefix}" 
  resource_group_name                            = azurerm_resource_group.rg.name
  location                                       = var.location

  type                                           = "Vnet2Vnet"
  virtual_network_gateway_id                     = azurerm_virtual_network_gateway.hub-vpngw.id
  peer_virtual_network_gateway_id                = azurerm_virtual_network_gateway.onprem-vpngw.id

  shared_key                                     = "4-v3ry-53cr37-1p53c-5h4r3d-k3y"  
}

# Azure Virtual Network peering between Virtual Network Hub and OnPrem
# resource "azurerm_virtual_network_peering" "peer_hub2onpremSpoke" {
#     name = "peer-vnet-hub-2-onprem"
#     resource_group_name = azurerm_resource_group.rg.name
#     virtual_network_name = azurerm_virtual_network.hub.name
#     remote_virtual_network_id = azurerm_virtual_network.client.id
#     allow_virtual_network_access = true
#     allow_forwarded_traffic = true
# }

# Azure Virtual Network peering between Virtual Network Hub and Server
resource "azurerm_virtual_network_peering" "peer_hub2serverSpoke" {
  name                         = "peer-vnet-hub-2-server"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.server.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Bastion - Module creates additional subnet (without NSG), public IP and Bastion
module "bastion" {
  source = "./modules/bastion"

  subnet_cidr                = "10.7.5.0/24"
  virtual_network_name       = azurerm_virtual_network.hub.name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  hub_prefix                 = var.hub_prefix
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

}

####################################### HUB-VNET DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "hub" {
  resource_id = azurerm_virtual_network.hub.id
}

resource "azurerm_monitor_diagnostic_setting" "hub" {
  name                       = "hubladiagnostics"
  target_resource_id         = azurerm_virtual_network.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.hub.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.hub.metrics

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

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}
