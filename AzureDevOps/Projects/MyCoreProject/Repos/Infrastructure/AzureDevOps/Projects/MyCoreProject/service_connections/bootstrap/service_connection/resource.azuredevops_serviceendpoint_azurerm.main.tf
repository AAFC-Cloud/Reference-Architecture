resource "azuredevops_serviceendpoint_azurerm" "main" {
  project_id                             = data.azuredevops_project.core_project.project_id
  service_endpoint_name                  = "MyCoreProject-Bootstrap-ServiceConnection"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  azurerm_spn_tenantid                   = data.azurerm_subscription.main.tenant_id
  azurerm_subscription_id                = data.azurerm_subscription.main.subscription_id
  azurerm_subscription_name              = data.azurerm_subscription.main.display_name

  credentials {
    serviceprincipalid = data.terraform_remote_state.bootstrap.outputs.application_client_id
  }
}
