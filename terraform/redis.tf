resource "azurerm_redis_cache" "redis" {
  name                = "${var.rg}-brief4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  redis_version       = 6
}

resource "azurerm_redis_firewall_rule" "vm_app" {
  name                = "vm_app"
  redis_cache_name    = azurerm_redis_cache.redis.name
  resource_group_name = azurerm_resource_group.rg.name
  start_ip            = azurerm_public_ip.public_ip_nat.ip_address
  end_ip              = azurerm_public_ip.public_ip_nat.ip_address
}
