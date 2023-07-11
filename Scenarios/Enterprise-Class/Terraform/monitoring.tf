# Adding a LogAnalytics Workspace for the globally shared resources
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "log-${var.hub_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730

  daily_quota_gb = 10

  tags = var.tags
}

resource "azurerm_storage_account" "monitoring-sto00" {
  name                     = "sto00netwatcherwgvlab"
  resource_group_name      = azurerm_resource_group.monitoring-rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
    
}

resource "azurerm_storage_account" "monitoring-sto01" {
  name                     = "sto01netwatcherwgvlab"
  resource_group_name      = azurerm_resource_group.monitoring-rg.name
  location                 = azurerm_resource_group.onprem-spoke-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
    
}

resource "azurerm_network_watcher" "monitoring-nwwatcher-eastus3" {
  name                = "nwwatcher-wgv-lab-eastus3"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.monitoring-rg.name
}

resource "azurerm_network_watcher" "monitoring-nwwatcher-westus3" {
  name                = "nwwatcher-wgv-lab-westus3"
  location            = azurerm_resource_group.onprem-spoke-rg.location
  resource_group_name = azurerm_resource_group.monitoring-rg.name
}

resource "azurerm_network_watcher_flow_log" "monitoring-nwwatcher-appflow-log" {
  network_watcher_name = azurerm_network_watcher.monitoring-nwwatcher-eastus3.name
  resource_group_name  = azurerm_resource_group.monitoring-rg.name
  name                 = "app-log"

  network_security_group_id = azurerm_network_security_group.app-nsg.id
  storage_account_id        = azurerm_storage_account.monitoring-sto00.id
  enabled                   = true
  version                   = 2

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.monitoring.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.monitoring.location
    workspace_resource_id = azurerm_log_analytics_workspace.monitoring.id
    interval_in_minutes   = 10
  }
}

resource "azurerm_network_watcher_flow_log" "monitoring-nwwatcher-onpremflow-log" {
  network_watcher_name = azurerm_network_watcher.monitoring-nwwatcher-westus3.name
  resource_group_name  = azurerm_resource_group.monitoring-rg.name
  name                 = "onprem-log"

  network_security_group_id = azurerm_network_security_group.onprem-nsg.id
  storage_account_id        = azurerm_storage_account.monitoring-sto01.id
  enabled                   = true
  version                   = 2
  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.monitoring.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.monitoring.location
    workspace_resource_id = azurerm_log_analytics_workspace.monitoring.id
    interval_in_minutes   = 10
  }
}