resource "azurerm_windows_virtual_machine" "compute" {

  name                            = var.server_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.compute.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version

  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_network_interface" "compute" {

  name                          = "${var.server_name}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking

  tags = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_application_security_group_association" "compute" {
  network_interface_id          = azurerm_network_interface.compute.id
  application_security_group_id = var.asg_datatier_id 
  
}

####################################### NIC DIAGNOSTIC SETTINGS #######################################

# Use this data source to fetch all available log and metrics categories. We then enable all of them
data "azurerm_monitor_diagnostic_categories" "compute" {
  resource_id = azurerm_network_interface.compute.id
}

resource "azurerm_monitor_diagnostic_setting" "compute" {
  name                       = "computehostladiagnostics"
  target_resource_id         = azurerm_network_interface.compute.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.compute.logs

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
    for_each = data.azurerm_monitor_diagnostic_categories.compute.metrics

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

variable "asg_datatier_id" {}

variable "admin_username" {
  default = "sysadmin"
}

variable "admin_password" {
  default = "changeme"
}

variable "server_name" {}

variable "resource_group_name" {}

variable "location" {}

variable "vnet_subnet_id" {}
variable "os_publisher" {
  default = "MicrosoftSQLServer"
}
variable "os_offer" {
  default = "sql2019-ws2019"
}
variable "os_sku" {
  default = "Web"
}
variable "os_version" {
  default = "latest"
}
variable "disable_password_authentication" {
  default = false #leave as true if using ssh key, if using a password make the value false
}
variable "enable_accelerated_networking" {
  default = "false"
}
variable "storage_account_type" {
  default = "Standard_LRS"
}
variable "vm_size" {
  default = "Standard_D2s_v3"
}
variable "tags" {
  type = map(string)

  default = {
    application = "compute"
  }
}

variable "allocation_method" {
  default = "Static"
}