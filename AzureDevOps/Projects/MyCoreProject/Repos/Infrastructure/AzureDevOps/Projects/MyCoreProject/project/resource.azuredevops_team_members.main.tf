resource "azuredevops_team_members" "main" {
  project_id = azuredevops_project.main.id
  team_id    = data.azuredevops_team.main.id
  members = [
    for user in local.people_with_descriptors :
    user.descriptor
  ]
  mode = "overwrite"
}
