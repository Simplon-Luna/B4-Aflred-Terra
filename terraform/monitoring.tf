resource "azurerm_monitor_action_group" "group-monitor" {
 resource_group_name = azurerm_resource_group.rg.name
 name                = "group-monitor"
 short_name          = "gm"
}

resource "azurerm_monitor_metric_alert" "alert-vm-cpu" {
 name                = "alert-vm-cpu"
 resource_group_name = azurerm_resource_group.rg.name
 scopes              = [azurerm_linux_virtual_machine.vm_app.id]
 description         = "VM App cpu alert"
 target_resource_type = "Microsoft.Compute/virtualMachines"

 criteria {
   metric_namespace = "Microsoft.Compute/virtualMachines"
   metric_name      = "Percentage CPU"
   aggregation      = "Total"
   operator         = "GreaterThan"
   threshold        = 70
 }

 action {
   action_group_id = azurerm_monitor_action_group.group-monitor.id
 }
}
