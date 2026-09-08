data "azuread_service_principal" "bootstrap" {
  object_id = data.terraform_remote_state.bootstrap.outputs.service_principal_object_id
}
