resource "azuread_application_api_access" "msgraph" {
  application_id = azuread_application_registration.main.id
  api_client_id  = data.azuread_service_principal.msgraph.client_id

  # Application.ReadWrite.OwnedBy supports app-registration lifecycle.
  # Group.Create permits creation of groups without granting group-membership
  # write access. Group.Read.All supports discovery without member mutation.
  role_ids = [
    data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.OwnedBy"],
    data.azuread_service_principal.msgraph.app_role_ids["Group.Create"],
    data.azuread_service_principal.msgraph.app_role_ids["Group.Read.All"],
    data.azuread_service_principal.msgraph.app_role_ids["User.Read.All"],
  ]
}
