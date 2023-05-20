resource "azurerm_ip_group" "ipgrp_deny" {
  name                = var.ipgroup_deny_prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

}

output "ipgrp_deny_hub_lab_id" {
  value = azurerm_ip_group.ipgrp_deny.id
}
