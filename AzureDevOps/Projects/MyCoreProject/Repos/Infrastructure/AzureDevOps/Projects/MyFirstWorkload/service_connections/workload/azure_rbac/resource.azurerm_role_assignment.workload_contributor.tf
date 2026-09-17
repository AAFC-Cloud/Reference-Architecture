resource "azurerm_role_assignment" "workload_contributor" {
  scope                            = data.azurerm_resource_group.main.id
  role_definition_name             = "Contributor"
  principal_id                     = data.terraform_remote_state.identity.outputs.service_principal_object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
