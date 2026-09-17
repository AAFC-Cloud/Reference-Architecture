resource "azuread_application_owner" "human" {
  for_each        = local.app_owner_object_ids
  application_id  = azuread_application_registration.main.id
  owner_object_id = each.value
}
