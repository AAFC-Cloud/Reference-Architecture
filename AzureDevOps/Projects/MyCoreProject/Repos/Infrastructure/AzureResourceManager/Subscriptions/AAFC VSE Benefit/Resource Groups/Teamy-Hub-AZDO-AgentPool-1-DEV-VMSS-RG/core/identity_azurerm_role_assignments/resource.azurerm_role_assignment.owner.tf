resource "azurerm_role_assignment" "resource_group_owner" {
  scope                = data.azurerm_resource_group.main.id
  principal_id         = data.azurerm_user_assigned_identity.main.principal_id
  role_definition_name = "Owner"
}
