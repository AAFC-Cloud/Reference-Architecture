data "azuredevops_environment" "change_approval" {
  for_each   = local.environment_names
  project_id = data.azuredevops_project.main.id
  name       = each.key
}
