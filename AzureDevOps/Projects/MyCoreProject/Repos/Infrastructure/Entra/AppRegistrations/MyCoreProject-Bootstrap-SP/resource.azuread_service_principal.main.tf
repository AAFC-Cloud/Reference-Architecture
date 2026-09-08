resource "azuread_service_principal" "main" {
  client_id = azuread_application_registration.main.client_id
  owners    = local.app_owner_object_ids
}
