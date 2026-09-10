data "azuread_service_principal" "msgraph" {
  # Microsoft Graph application ID from the AzureAD provider's well-known map.
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}
