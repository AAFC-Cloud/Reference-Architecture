resource "azurerm_app_configuration" "main" {
  # App Configuration names are global; the resource-group ID adds a stable suffix.
  name                = "teamy-workload-myfirstworkload-dev-${substr(sha256(lower(data.azurerm_resource_group.main.id)), 0, 8)}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "free"
  local_auth_enabled  = false
  tags                = data.azurerm_resource_group.main.tags
}
