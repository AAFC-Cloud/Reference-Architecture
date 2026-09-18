# The image VM creates a NIC in the shared network subnet. Keep this
# permission scoped to that subnet rather than granting network access to the
# whole shared network resource group.
resource "azurerm_role_assignment" "network_subnet_contributor" {
  scope                = "/subscriptions/6cb7032f-2437-4f5e-91e8-676cb67e5444/resourceGroups/TEAMY-NETWORK-RG/providers/Microsoft.Network/virtualNetworks/TEAMY-NETWORK-VNET/subnets/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-snet"
  principal_id         = data.azurerm_user_assigned_identity.main.principal_id
  role_definition_name = "Network Contributor"
}
