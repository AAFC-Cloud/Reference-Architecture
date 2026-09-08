data "azurerm_user_assigned_identity" "agent_pool" {
  name                = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-MI"
  resource_group_name = data.azurerm_resource_group.main.name
}
