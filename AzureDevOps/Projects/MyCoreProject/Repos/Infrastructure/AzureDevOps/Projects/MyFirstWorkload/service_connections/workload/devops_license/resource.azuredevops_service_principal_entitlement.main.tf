resource "azuredevops_service_principal_entitlement" "main" {
  # Organization onboarding is separate from project membership.
  origin               = "aad"
  origin_id            = data.terraform_remote_state.identity.outputs.service_principal_object_id
  account_license_type = "express"
}
