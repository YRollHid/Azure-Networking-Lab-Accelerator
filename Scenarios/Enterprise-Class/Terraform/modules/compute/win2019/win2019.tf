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
  application_security_group_id = var.asg_webtier_id 
  
}

# Automated Backend Pool Addition > Gem Configuration to add the network interfaces of the VMs to the backend pool.
resource "azurerm_network_interface_backend_address_pool_association" "compute" {
  count                   = 1
  network_interface_id    = azurerm_network_interface.compute.*.id[count.index]
  ip_configuration_name   = azurerm_network_interface.compute.*.ip_configuration.0.name[count.index]
  backend_address_pool_id = var.backend_address_pool_id

}

resource "azurerm_virtual_machine_extension" "custom_script" {
  name                       = var.server_name
  virtual_machine_id         = azurerm_windows_virtual_machine.compute.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "fileUris": [
          "${var.template_base_url}artifacts/deploy-cloudshop.ps1"
      ],
      "commandToExecute": "powershell.exe -ExecutionPolicy Bypass -File deploy-cloudshop.ps1 -cloudshopurl ${var.cloudshopurl}"
    }
SETTINGS
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

variable "asg_webtier_id" {}

variable "backend_address_pool_id" {}

variable "template_base_url" {
  default = "https://raw.githubusercontent.com/yrollhid/Azure-Networking-Lab-Accelerator/main/Scenarios/Enterprise-Class/"
}
variable "cloudshopurl" {
  default = "https://cloudworkshop.blob.core.windows.net/enterprise-networking/Cloudshop.zip"
}
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
  default = "MicrosoftWindowsServer"
}
variable "os_offer" {
  default = "WindowsServer"
}
variable "os_sku" {
  default = "2019-datacenter-gensecond"
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