resource "azuredevops_service_principal_entitlement" "main" {
  origin    = "aad"
  origin_id = data.terraform_remote_state.bootstrap.outputs.service_principal_object_id

  # Express is the provider value for the Basic-equivalent entitlement.
  account_license_type = "express"

  # depends_on = [time_sleep.entra_service_principal_ready]
}
