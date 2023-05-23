# Firewall Policy

resource "azurerm_firewall_policy" "compute" {
  name                = "policy-fw-${var.hub_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

output "fw_policy_id" {
  value = azurerm_firewall_policy.compute.id
}

# Rules Collection Group

resource "azurerm_firewall_policy_rule_collection_group" "compute" {
  name               = "compute-rcg"
  firewall_policy_id = azurerm_firewall_policy.compute.id
  priority           = 200
  application_rule_collection {
    name     = "Web_Categories_Rules"
    priority = 205
    action   = "Allow"
    rule {
      name = "web_categories"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses = ["192.168.1.0/24","10.8.0.0/25","10.8.1.0/25"]
      web_categories   = ["computersandtechnology"]
    }
  }

  network_rule_collection {
    name     = "Deny_Traffic"
    priority = 200
    action   = "Deny"
    rule {
      name      = "BlockPortScanners"
      protocols = ["Any"]
      source_ip_groups      = [var.ipgrp_deny_hub_lab_id]
      destination_addresses = ["172.16.1.0/24"]
      destination_ports     = ["*"]
    }

  }

  network_rule_collection {
    name     = "VNET_Access"
    priority = 210
    action   = "Allow"
    rule {
      name                  = "AllowAll"
      protocols             = ["Any"]
      source_addresses      = ["192.168.1.0/24"]
      destination_addresses = ["172.16.1.0/24"]
      destination_ports     = ["*"]
    }

  }

  # network_rule_collection {
  #   name     = "DataTier_Access"
  #   priority = 220
  #   action   = "Allow"
  #   rule {
  #     name                  = "AllowMSSQL"
  #     protocols             = ["TCP"]
  #     source_addresses      = ["10.8.0.0/25"]
  #     destination_addresses = ["10.8.1.0/25"]
  #     destination_ports     = ["1433"]
  #   }

  # }

}

variable "resource_group_name" {}

variable "location" {}

variable "hub_prefix" {}

variable "ipgrp_deny_hub_lab_id" {}
