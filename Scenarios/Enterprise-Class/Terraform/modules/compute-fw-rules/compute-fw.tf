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
    name     = "WebCategoriesRules1"
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
    name     = "NetworkRuleCollectionDeny1"
    priority = 200
    action   = "Deny"
    rule {
      name      = "BlockPortScanners"
      protocols = ["Any"]
      source_ip_groups      = [var.ipgrp_deny_hub_lab_id]
      destination_addresses = ["10.8.0.0/20"]
      destination_ports     = ["*"]
    }

  }

  network_rule_collection {
    name     = "NetworkRuleCollectionAllow1"
    priority = 210
    action   = "Allow"
    rule {
      name                  = "AllowAll"
      protocols             = ["Any"]
      source_addresses      = ["192.168.0.0/24"]
      destination_addresses = ["10.8.0.0/25"]
      destination_ports     = ["*"]
    }

  }

  nat_rule_collection {
    name     = "NATRuleCollection1"
    priority = 250
    action   = "Dnat"
    rule {
      name                = "IncomingHTTP"
      protocols           = ["TCP"]
      source_addresses    = ["*"]
      destination_address = var.az_fw_pip
      destination_ports   = ["80"]
      translated_address  = "10.8.0.100"
      translated_port     = "80"
    }
  }

}

variable "resource_group_name" {}

variable "location" {}

variable "hub_prefix" {}

variable "az_fw_pip" {}

variable "ipgrp_deny_hub_lab_id" {}
