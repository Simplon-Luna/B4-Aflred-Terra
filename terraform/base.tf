resource "azurerm_resource_group" "rg" {
  name      = var.rg
  location  = var.location
}

resource "azurerm_virtual_network" "network" {
  name                = "vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_ssh_public_key" "ssh_key" {
  name                = "ssh_key_admin"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("~/.ssh/id_rsa.pub") 
}
