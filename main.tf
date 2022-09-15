## RG
    # Resource group name creation
resource "random_pet" "rg_name" {
  prefix = var.rg
}

    # Resource group creation
resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.location
}

## Creation VNetwork
resource "azurerm_virtual_network" "network" {
  name                = "${var.prefix}vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

## Creation SSH
    # SSH Luna
resource "azurerm_ssh_public_key" "ssh_key1" {
  name                = "ssh_key_admin"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("ssh/ssh.pub") 
}

    # SSH Dunvael
resource "azurerm_ssh_public_key" "ssh_key2" {
  name                = "ssh_key_usr1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("ssh/ssh2.pub") 
}

    # SSH Yuta
resource "azurerm_ssh_public_key" "ssh_key3" {
  name                = "ssh_key_usr2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_key          = file("ssh/ssh3.pub") 
} 

## Creation SubNet
resource "azurerm_subnet" "subnet_gateway" {
  name                 = "${var.prefix}subnet_gateway"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.1.0/24"]
}

## Creation Gateway PublicIP
resource "azurerm_public_ip" "public_ip_gateway" {
  name                = "${var.prefix}public_ip_gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${lower(var.subdomain-prefix)}-${lower(var.rg)}"
}

## Creation & Config AppGateway
resource "azurerm_application_gateway" "gateway" {
  name                = "${var.prefix}gateway"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
 }

  gateway_ip_configuration {
    name      = "${var.prefix}ip-configuration"
    subnet_id = azurerm_subnet.subnet_gateway.id
 }

  frontend_port {
    name = "http"
    port = 80
 }

  frontend_ip_configuration {
    name                 = "${var.prefix}front-ip"
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
    name                           = "${var.prefix}listener"
    frontend_ip_configuration_name = "${var.prefix}front-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
 }

  request_routing_rule {
    name                       = "rule-1"
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}listener"
    backend_address_pool_name  = "backend_pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
 }
}

## AppGateway PoolEnd
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "poolbackend" {
 network_interface_id    = azurerm_network_interface.nic_app.id
 ip_configuration_name   = "${var.prefix}nic_app_config"
 backend_address_pool_id = tolist(azurerm_application_gateway.gateway.backend_address_pool).0.id
}

## NAT
    # Creation NAT PubIP
resource "azurerm_public_ip" "public_ip_nat" {
  name                = "${var.prefix}public-ip-nat"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

    # Creation Nat Gateway
resource "azurerm_nat_gateway" "nat_gw" {
  name                    = "${var.prefix}nat-gw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku_name                = "Standard"
}

    # Association NAT & Pub IP
resource "azurerm_nat_gateway_public_ip_association" "gw_ip_a" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.public_ip_nat.id
}

    # Association Nat Gateway
resource "azurerm_subnet_nat_gateway_association" "gw_a" {
  subnet_id      = azurerm_subnet.subnet_app.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

## Bastion
    # Creation Bastion Subnet
resource "azurerm_subnet" "subnet_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.0.0/24"]
}

    # Creation Bastion PubIP
resource "azurerm_public_ip" "public_ip_bastion" {
  name                = "${var.prefix}public_ip_bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

    # Creation Bastion
resource "azurerm_bastion_host" "bastion" {
  name                = "${var.prefix}bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tunneling_enabled   = true
  ip_connect_enabled  = true
  sku                 = "Standard"

  ip_configuration {
    name                 = "${var.prefix}bastion_ip"
    subnet_id            = azurerm_subnet.subnet_bastion.id
    public_ip_address_id = azurerm_public_ip.public_ip_bastion.id
  }
}

#**# ## VM
#**#     # Creation VM Subnet
#**# resource "azurerm_subnet" "subnet_app" {
#**#   name                 = "${var.prefix}subnet_app"
#**#   resource_group_name  = azurerm_resource_group.rg.name
#**#   virtual_network_name = azurerm_virtual_network.network.name
#**#   address_prefixes     = ["10.0.2.0/24"]
#**# }
#**# 
#**#     # Creation Nic App
#**# resource "azurerm_network_interface" "nic_app" {
#**#   name                = "${var.prefix}nic_app"
#**#   location            = azurerm_resource_group.rg.location
#**#   resource_group_name = azurerm_resource_group.rg.name
#**# 
#**#   ip_configuration {
#**#     name                          = "${var.prefix}nic_app_config"
#**#     subnet_id                     = azurerm_subnet.subnet_app.id
#**#     private_ip_address_allocation = "Dynamic"
#**#   }
#**# }
#**# 
#**#     # Creation NSG App
#**# resource "azurerm_network_security_group" "nsg_app" {
#**#   name                = "${var.prefix}nsg_app"
#**#   location            = azurerm_resource_group.rg.location
#**#   resource_group_name = azurerm_resource_group.rg.name
#**# 
#**#   security_rule {
#**#     name                       = "HTTP"
#**#     priority                   = 100
#**#     direction                  = "Inbound"
#**#     access                     = "Allow"
#**#     protocol                   = "Tcp"
#**#     source_port_range          = "*"
#**#     destination_port_range     = "80"
#**#     source_address_prefix      = "*"
#**#     destination_address_prefix = "*"
#**#   }
#**# }
#**# 
#**#     # Association NIC & NSG
#**# resource "azurerm_network_interface_security_group_association" "assoc-nic-nsg-app" {
#**#   network_interface_id      = azurerm_network_interface.nic_app.id
#**#   network_security_group_id = azurerm_network_security_group.nsg_app.id
#**# }

## Redis
    # Creation Redis
resource "azurerm_redis_cache" "redis" {
  name                = "${var.prefix}-brief4"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  redis_version       = 6
}

    # Creadtion Redis Firewall Rule
resource "azurerm_redis_firewall_rule" "vm_app" {
  name                = "${var.prefix}vm_app"
  redis_cache_name    = azurerm_redis_cache.redis.name
  resource_group_name = azurerm_resource_group.rg.name
  start_ip            = azurerm_public_ip.public_ip_nat.ip_address
  end_ip              = azurerm_public_ip.public_ip_nat.ip_address
}

## Creation Storage Account
resource "azurerm_storage_account" "stor_acc" {
  name                     = "${var.prefix}storageacc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "staging"
  }
}

## Creation & Setting VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "scalevmss" {
  name                = "${var.prefix}exampleset"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  upgrade_mode        = "Manual"
  sku                 = "Standard_F2"
  instances           = 2
  admin_username      = "wonderwomen"
  custom_data          = data.cloudinit_config.cloud-init.rendered

  admin_ssh_key {
    username   = "wonderwomen"
    public_key = azurerm_ssh_public_key.ssh_key1.public_key
  }
  network_interface {
    name    = "${var.prefix}NetworkInterfaceProfile"
    primary = true

    ip_configuration {
      name      = "${var.prefix}IPConfiguration"
      primary   = true
      subnet_id = azurerm_subnet.subnet_app.id
      application_gateway_backend_address_pool_ids = tolist(azurerm_application_gateway.gateway.backend_address_pool).0.id
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscaleset" {
  name                = "${var.prefix}AutoscaleSetting"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.scalevmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.scalevmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.scalevmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = "${var.adminmail}"
    }
  }
}

#*# ## Creation VM App
#*# resource "azurerm_linux_virtual_machine" "vm_app" {
#*#   name                  = "${var.prefix}vm-app"
#*#   location              = azurerm_resource_group.rg.location
#*#   resource_group_name   = azurerm_resource_group.rg.name
#*#   network_interface_ids = [azurerm_network_interface.nic_app.id]
#*#   size                  = "Standard_DS1_v2"
#*# 
#*#   os_disk {
#*#     name                 = "${var.prefix}disk_app"
#*#     caching              = "ReadWrite"
#*#     storage_account_type = "Premium_LRS"
#*#   }
#*# 
#*#   source_image_reference {
#*#     publisher = "Debian"
#*#     offer     = "debian-11"
#*#     sku       = "11"
#*#     version   = "latest"
#*#   }
#*# 
#*#   custom_data                     = data.cloudinit_config.cloud-init.rendered
#*#   admin_username                  = "wonderwomen"
#*#   disable_password_authentication = true
#*#
#*#  admin_ssh_key {
#*#     username   = "wonderwomen"
#*#     public_key = azurerm_ssh_public_key.ssh_key1.public_key
#*#   }
#*# }


#*# ## ---- Monitoring ----
#*#     # Creation Monitor Action Group
#*# resource "azurerm_monitor_action_group" "group-monitor" {
#*#  resource_group_name = azurerm_resource_group.rg.name
#*#  name                = "${var.prefix}group-monitor"
#*#  short_name          = "gm"
#*# }
#*# 
#*#     # Creation Metric Alert
#*# resource "azurerm_monitor_metric_alert" "alert-vm-cpu" {
#*#  name                = "${var.prefix}alert-vm-cpu"
#*#  resource_group_name = azurerm_resource_group.rg.name
#*#  scopes              = [azurerm_linux_virtual_machine_scale_set.scalevmss.id]
#*#  description         = "VM App cpu alert"
#*#  target_resource_type = "Microsoft.Compute/virtualMachines"
#*# 
#*#  criteria {
#*#    metric_namespace = "Microsoft.Compute/virtualMachines"
#*#    metric_name      = "Percentage CPU"
#*#    aggregation      = "Total"
#*#    operator         = "GreaterThan"
#*#    threshold        = 70
#*#  }
#*# 
#*#  action {
#*#    action_group_id = azurerm_monitor_action_group.group-monitor.id
#*#  }
#*# }
#*# 