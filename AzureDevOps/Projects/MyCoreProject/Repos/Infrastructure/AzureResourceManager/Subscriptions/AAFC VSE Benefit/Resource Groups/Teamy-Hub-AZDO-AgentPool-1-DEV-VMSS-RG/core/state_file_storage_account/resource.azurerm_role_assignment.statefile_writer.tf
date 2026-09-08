resource "azurerm_role_assignment" "statefile_writer" {
  principal_id         = data.azurerm_user_assigned_identity.main.principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_container.statefiles.id
}
