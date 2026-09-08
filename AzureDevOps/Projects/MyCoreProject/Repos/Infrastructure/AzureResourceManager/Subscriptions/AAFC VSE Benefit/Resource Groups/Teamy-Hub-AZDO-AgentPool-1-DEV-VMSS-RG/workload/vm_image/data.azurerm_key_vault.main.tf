data "azurerm_key_vault" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  name                = "TeamyHubAZDOAgentPool1KV"
}
