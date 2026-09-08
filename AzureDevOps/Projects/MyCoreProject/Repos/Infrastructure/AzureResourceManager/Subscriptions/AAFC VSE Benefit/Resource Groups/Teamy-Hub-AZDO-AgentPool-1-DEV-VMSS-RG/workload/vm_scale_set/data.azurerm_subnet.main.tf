data "azurerm_subnet" "main" {
  resource_group_name  = "TEAMY-NETWORK-RG"
  virtual_network_name = "TEAMY-NETWORK-VNET"
  name                 = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-snet"
}
