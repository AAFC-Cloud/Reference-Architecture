# Adopt the creator ownership on the existing application. The application ID
# must be known during planning, and the owner relationship must already exist.
import {
  to = azuread_application_owner.bootstrap
  id = "${azuread_application_registration.main.id}/owners/${data.azuread_client_config.current.object_id}"
}

resource "azuread_application_owner" "bootstrap" {
  application_id  = azuread_application_registration.main.id
  owner_object_id = data.azuread_client_config.current.object_id
}
