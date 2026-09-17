data "azuredevops_group" "workload_project_administrators" {
  project_id = data.azuredevops_project.workload.id
  name       = "Project Administrators"
}
