data "azuredevops_serviceendpoint_azurerm" "main" {
  for_each              = local.service_endpoint_names
  project_id            = data.azuredevops_project.main.id
  service_endpoint_name = each.key
}
