data "azurerm_user_assigned_identity" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  name                = "${trimsuffix(data.azurerm_resource_group.main.name, "-RG")}-MI"
}
