resource "azurerm_role_assignment" "statefile_writer" {
  principal_id         = data.terraform_remote_state.identity.outputs.service_principal_object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_container.statefiles.id
}
