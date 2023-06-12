# Resource-1: Create Azure Standard Load Balancer
resource "azurerm_lb" "app_lb" {
  name                = "	lbi-app-${var.server_prefix}"
  resource_group_name = azurerm_resource_group.server-spoke-rg.name
  location            = azurerm_resource_group.rg.location
  sku = "Standard"
  frontend_ip_configuration {
    name                 = "WGWEBLBIP"
    subnet_id = azurerm_subnet.app-spoke.id
    private_ip_address_allocation = "Static"
    private_ip_address_version = "IPv4"
    private_ip_address = "10.8.0.100"
  }
}

# Resource-3: Create LB Backend Pool
resource "azurerm_lb_backend_address_pool" "app_lb_backend_address_pool" {
  name                = "LBBE"
  loadbalancer_id     = azurerm_lb.app_lb.id
}

# Resource-4: Create LB Probe
resource "azurerm_lb_probe" "app_lb_probe" {
  name                = "HTTP"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  loadbalancer_id     = azurerm_lb.app_lb.id
}

# Resource-5: Create LB Rule
resource "azurerm_lb_rule" "app_lb_rule_app" {
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.app_lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_lb_backend_address_pool.id] 
  probe_id                       = azurerm_lb_probe.app_lb_probe.id
  loadbalancer_id                = azurerm_lb.app_lb.id
}
