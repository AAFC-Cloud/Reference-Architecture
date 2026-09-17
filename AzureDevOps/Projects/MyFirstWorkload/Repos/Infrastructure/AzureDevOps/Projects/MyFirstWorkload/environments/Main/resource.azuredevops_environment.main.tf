resource "azuredevops_environment" "main" {
  project_id  = data.azuredevops_project.main.id
  name        = "MyFirstWorkload-DEV"
  description = "Review the App Configuration plan before applying it."
}
