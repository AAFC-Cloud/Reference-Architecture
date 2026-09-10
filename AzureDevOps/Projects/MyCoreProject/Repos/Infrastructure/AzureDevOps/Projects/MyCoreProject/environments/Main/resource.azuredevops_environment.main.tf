resource "azuredevops_environment" "main" {
  name        = "MyCoreProject-Core-Environment"
  project_id  = data.azuredevops_project.main.id
  description = "Primary deployment environment"
}
