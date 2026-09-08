resource "azurerm_role_assignment" "tenant_root_owner" {
  principal_id         = data.terraform_remote_state.bootstrap.outputs.service_principal_object_id
  role_definition_name = "Owner"
  scope                = "/providers/Microsoft.Management/managementGroups/${data.azurerm_client_config.current.tenant_id}"
}
