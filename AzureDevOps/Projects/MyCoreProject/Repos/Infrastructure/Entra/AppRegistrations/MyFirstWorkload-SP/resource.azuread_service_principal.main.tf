resource "azuread_service_principal" "main" {
  client_id = azuread_application_registration.main.client_id
  owners    = setunion(local.app_owner_object_ids, [data.azuread_client_config.current.object_id])
}
