resource "azuread_application_owner" "self" {
  application_id  = azuread_application_registration.main.id
  owner_object_id = azuread_service_principal.main.object_id
}
