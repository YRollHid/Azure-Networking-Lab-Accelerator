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

resource "azurerm_storage_account" "monitoring-sto" {
  name                     = "sto00netwatcherwgvlab"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
    
}