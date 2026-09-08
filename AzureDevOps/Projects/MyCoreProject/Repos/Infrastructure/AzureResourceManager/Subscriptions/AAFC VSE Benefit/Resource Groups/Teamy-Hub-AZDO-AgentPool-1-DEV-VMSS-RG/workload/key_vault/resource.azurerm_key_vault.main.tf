resource "azurerm_key_vault" "main" {
  resource_group_name        = data.azurerm_resource_group.main.name
  tags                       = data.azurerm_resource_group.main.tags
  location                   = data.azurerm_resource_group.main.location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  name                       = "TeamyHubAZDOAgentPool1KV"
  rbac_authorization_enabled = true
}
