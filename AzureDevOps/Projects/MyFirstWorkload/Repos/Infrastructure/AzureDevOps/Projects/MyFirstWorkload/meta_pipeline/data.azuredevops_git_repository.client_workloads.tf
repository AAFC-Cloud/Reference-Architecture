data "azuredevops_git_repository" "client_workloads" {
  project_id = data.azuredevops_project.main.id
  name       = "Infrastructure"
}
