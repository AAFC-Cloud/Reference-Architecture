resource "azurerm_role_assignment" "bootstrap_statefile_writer" {
  principal_id         = data.azuread_service_principal.bootstrap.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_container.statefiles.id
}
