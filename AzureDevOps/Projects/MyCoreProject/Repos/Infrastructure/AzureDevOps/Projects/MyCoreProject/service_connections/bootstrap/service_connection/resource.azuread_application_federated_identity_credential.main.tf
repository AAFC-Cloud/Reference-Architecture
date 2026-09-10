resource "azuread_application_federated_identity_credential" "main" {
  application_id = data.terraform_remote_state.bootstrap.outputs.application_object_id
  display_name   = "AzureDevOpsServiceConnection"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = azuredevops_serviceendpoint_azurerm.main.workload_identity_federation_issuer
  subject        = azuredevops_serviceendpoint_azurerm.main.workload_identity_federation_subject
}
