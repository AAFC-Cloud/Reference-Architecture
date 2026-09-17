resource "azuread_application_registration" "main" {
  display_name     = "MyFirstWorkload-SP"
  description      = "Deployment identity for the MyFirstWorkload resource group."
  sign_in_audience = "AzureADMyOrg"
}
