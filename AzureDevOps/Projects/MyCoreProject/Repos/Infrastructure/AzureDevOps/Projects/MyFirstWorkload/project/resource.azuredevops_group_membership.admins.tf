resource "azuredevops_group_membership" "admins" {
  group = data.azuredevops_group.admins.descriptor
  members = [
    for user in local.people_with_descriptors :
    user.descriptor
    if user.is_project_admin
  ]
  # Service-principal membership is managed by devops_project_permissions.
  # Add only these people so applying this root preserves that membership.
  mode = "add"
}
