data "azuredevops_group" "core_project_endpoint_administrators" {
  project_id = data.azuredevops_project.core_project.id
  name       = "Endpoint Administrators"
}
