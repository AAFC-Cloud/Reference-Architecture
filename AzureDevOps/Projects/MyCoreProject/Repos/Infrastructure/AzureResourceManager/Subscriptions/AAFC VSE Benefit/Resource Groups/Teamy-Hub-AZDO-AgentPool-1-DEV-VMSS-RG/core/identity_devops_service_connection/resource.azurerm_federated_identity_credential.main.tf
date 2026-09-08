resource "azurerm_federated_identity_credential" "main" {
  user_assigned_identity_id = data.azurerm_user_assigned_identity.main.id
  name                      = azuredevops_serviceendpoint_azurerm.main.service_endpoint_name
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azuredevops_serviceendpoint_azurerm.main.workload_identity_federation_issuer
  subject                   = azuredevops_serviceendpoint_azurerm.main.workload_identity_federation_subject
}
