data "azuredevops_group" "core_project_project_administrators" {
  project_id = data.azuredevops_project.core_project.id
  name       = "Project Administrators"
}
