output "application-address" {
  value = "http://${azurerm_public_ip.public_ip_gateway.fqdn}"
}