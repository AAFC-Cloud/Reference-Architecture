data "azurerm_virtual_machine_scale_set" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  name                = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS"
}
