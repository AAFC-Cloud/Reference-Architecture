resource "azurerm_user_assigned_identity" "main" {
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = data.azurerm_resource_group.main.tags
  name                = "${trimsuffix(data.azurerm_resource_group.main.name, "-RG")}-MI"
}
