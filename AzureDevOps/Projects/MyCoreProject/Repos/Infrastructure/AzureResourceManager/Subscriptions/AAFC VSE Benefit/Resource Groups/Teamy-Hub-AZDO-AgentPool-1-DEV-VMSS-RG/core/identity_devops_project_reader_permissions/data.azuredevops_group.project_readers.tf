data "azuredevops_group" "project_readers" {
  for_each = toset(data.azuredevops_projects.main.projects[*].project_id)

  project_id = each.value
  name       = "Readers"
}
