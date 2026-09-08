resource "azurerm_resource_group" "main" {
  location = "canadacentral"
  name     = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG"
  tags = {
    Classification = "Unclassified"
  }
}
