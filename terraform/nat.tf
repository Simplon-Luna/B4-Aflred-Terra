resource "azurerm_public_ip" "public_ip_nat" {
  name                = "public-ip-nat"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                    = "nat-gw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "gw_ip_a" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.public_ip_nat.id
}

resource "azurerm_subnet_nat_gateway_association" "gw_a" {
  subnet_id      = azurerm_subnet.subnet_app.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}
