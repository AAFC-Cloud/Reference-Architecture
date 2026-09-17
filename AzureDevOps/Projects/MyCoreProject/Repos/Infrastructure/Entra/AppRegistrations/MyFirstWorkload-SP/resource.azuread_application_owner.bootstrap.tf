resource "azuread_application_owner" "bootstrap" {
  application_id  = azuread_application_registration.main.id
  owner_object_id = data.azuread_client_config.current.object_id
}
