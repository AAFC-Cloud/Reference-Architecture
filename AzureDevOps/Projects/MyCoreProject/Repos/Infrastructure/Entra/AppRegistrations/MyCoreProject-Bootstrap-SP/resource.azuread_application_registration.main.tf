resource "azuread_application_registration" "main" {
  display_name     = "MyCoreProject-Bootstrap-SP"
  description      = "The central, protected principal for bootstrapping core resources, identities, service connections, environments, and role assignments."
  sign_in_audience = "AzureADMyOrg"
}
