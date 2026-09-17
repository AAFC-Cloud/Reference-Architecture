data "azuredevops_service_principal" "main" {
  origin_id = data.terraform_remote_state.identity.outputs.service_principal_object_id
}
