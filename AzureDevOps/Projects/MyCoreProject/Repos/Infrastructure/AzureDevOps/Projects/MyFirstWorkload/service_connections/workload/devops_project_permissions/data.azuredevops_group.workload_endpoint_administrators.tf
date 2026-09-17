data "azuredevops_group" "workload_endpoint_administrators" {
  project_id = data.azuredevops_project.workload.id
  name       = "Endpoint Administrators"
}
