####################################
# These resources will use app & data subnet for user connectivity
# to the VMs with the Bastion Service.
####################################

resource "azurerm_network_security_group" "app-nsg" {
  name                = "${azurerm_virtual_network.server.name}-${azurerm_subnet.app-spoke.name}-nsg"
  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "AllowDataTierInboundTCP1433"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_application_security_group_ids = [azurerm_application_security_group.webtier.id]
    source_port_range          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.datatier.id]
    destination_port_range     = "1433"
  }
  security_rule {
    name                       = "AllowWebTierInboundTCP80"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.webtier.id]
    destination_port_range     = "80"
    source_address_prefix      = "*"
  }
  security_rule {
    name                       = "AllowMgmtInboundWeb3389"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.webtier.id]
    destination_port_range     = "3389"
    source_address_prefixes    = ["10.7.2.0/25","10.7.5.0/24"]
  }
    security_rule {
    name                       = "AllowMgmtInboundData3389"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.datatier.id]
    destination_port_range     = "3389"
    source_address_prefixes    = ["10.7.2.0/25","10.7.5.0/24"]
  }
  security_rule {
    name                       = "DenyVNetDataTierInbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.datatier.id]
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
  }
  security_rule {
    name                       = "DenyVNetWebTierInbound"
    priority                   = 1050
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.webtier.id]
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
  }


}

resource "azurerm_subnet_network_security_group_association" "app-subnet" {
  subnet_id                 = azurerm_subnet.app-spoke.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}
resource "azurerm_subnet_network_security_group_association" "data-subnet" {
  subnet_id                 = azurerm_subnet.data-spoke.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id
}

# Win2019 Server VM

module "create_WGWEB1" {
  source = "./modules/compute/win2019"

  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnet_id      = azurerm_subnet.app-spoke.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  asg_webtier_id      = azurerm_application_security_group.webtier.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_lb_backend_address_pool.id

  server_name    = "WGWEB1"
  admin_username = var.server_admin_username
  admin_password = var.server_admin_password
  

}

# Win2019 Server VM

module "create_WGWEB2" {
  source = "./modules/compute/win2019"

  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnet_id      = azurerm_subnet.app-spoke.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  asg_webtier_id      = azurerm_application_security_group.webtier.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_lb_backend_address_pool.id

  server_name    = "WGWEB2"
  admin_username = var.server_admin_username
  admin_password = var.server_admin_password
  

}

# Win2019 SQL Server VM

module "create_WGSQL1" {
  source = "./modules/compute/win2019sql"

  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnet_id      = azurerm_subnet.data-spoke.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id
  asg_datatier_id     = azurerm_application_security_group.datatier.id


  server_name    = "WGSQL1"
  admin_username = var.server_admin_username
  admin_password = var.server_admin_password

}

####################################### SERVER-SPOKE-NSG DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "app-nsg" {
  resource_id = azurerm_network_security_group.app-nsg.id
}

 resource "azurerm_monitor_diagnostic_setting" "app-nsg" {
   name                       = "app-nsgladiagnostics"
   target_resource_id         = azurerm_network_security_group.app-nsg.id
   log_analytics_workspace_id = azurerm_log_analytics_workspace.monitoring.id

  dynamic "log" {
     iterator = entry
     for_each = data.azurerm_monitor_diagnostic_categories.app-nsg.logs

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
     for_each = data.azurerm_monitor_diagnostic_categories.app-nsg.metrics

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

variable "server_admin_password" {
  default = "changeme"
}

variable "server_admin_username" {
  default = "sysadmin"
}
