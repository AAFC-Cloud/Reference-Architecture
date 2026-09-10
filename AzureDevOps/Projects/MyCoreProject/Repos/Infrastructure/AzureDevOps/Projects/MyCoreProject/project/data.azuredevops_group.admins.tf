data "azuredevops_group" "admins" {
  project_id = azuredevops_project.main.id
  name       = "Project Administrators"
}
