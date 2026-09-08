resource "azuredevops_service_principal_entitlement" "main" {
  origin    = "aad"
  origin_id = data.azurerm_user_assigned_identity.main.principal_id

  # Express is the provider value for the Basic-equivalent entitlement.
  account_license_type = "express"
}
