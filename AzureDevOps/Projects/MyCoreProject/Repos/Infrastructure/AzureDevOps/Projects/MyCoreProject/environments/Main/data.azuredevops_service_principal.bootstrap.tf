data "azuredevops_service_principal" "bootstrap" {
  origin_id = data.terraform_remote_state.bootstrap.outputs.service_principal_object_id
}
