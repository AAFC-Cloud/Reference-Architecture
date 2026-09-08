data "azuredevops_serviceendpoint_azurerm" "serviceendpoint" {
  project_id            = data.azuredevops_project.main.id
  service_endpoint_name = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-MI-SC"
}
