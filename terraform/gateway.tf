resource "azurerm_subnet" "subnet_gateway" {
  name                 = "subnet_gateway"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip_gateway" {
  name                = "public_ip_gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
  domain_name_label = var.subdomain
}

resource "azurerm_application_gateway" "gateway" {
 name                = "gateway"
 resource_group_name = azurerm_resource_group.rg.name
 location            = azurerm_resource_group.rg.location

 sku {
   name     = "Standard_v2"
   tier     = "Standard_v2"
   capacity = 2
 }

 gateway_ip_configuration {
   name      = "ip-configuration"
   subnet_id = azurerm_subnet.subnet_gateway.id
 }

 frontend_port {
   name = "http"
   port = 80
 }

 frontend_ip_configuration {
   name                 = "front-ip"
   public_ip_address_id = azurerm_public_ip.public_ip_gateway.id
 }

 backend_address_pool {
   name = "backend_pool"
 }

 backend_http_settings {
   name                  = "http-settings"
   cookie_based_affinity = "Disabled"
   path                  = "/"
   port                  = 80
   protocol              = "Http"
   request_timeout       = 10
 }

 http_listener {
   name                           = "listener"
   frontend_ip_configuration_name = "front-ip"
   frontend_port_name             = "http"
   protocol                       = "Http"
 }

 request_routing_rule {
   name                       = "rule-1"
   rule_type                  = "Basic"
   http_listener_name         = "listener"
   backend_address_pool_name  = "backend_pool"
   backend_http_settings_name = "http-settings"
   priority                   = 100
 }
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "poolbackend" {
 network_interface_id    = azurerm_network_interface.nic_app.id
 ip_configuration_name   = "nic_app_config"
 backend_address_pool_id = tolist(azurerm_application_gateway.gateway.backend_address_pool).0.id
}
