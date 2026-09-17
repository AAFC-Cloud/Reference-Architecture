data "azuredevops_team" "main" {
  project_id = azuredevops_project.main.id
  name       = "${azuredevops_project.main.name} Team"
}
