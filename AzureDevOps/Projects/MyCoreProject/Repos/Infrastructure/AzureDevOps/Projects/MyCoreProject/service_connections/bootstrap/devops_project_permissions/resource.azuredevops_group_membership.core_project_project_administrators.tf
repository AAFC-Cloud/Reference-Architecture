resource "azuredevops_group_membership" "core_project_project_administrators" {
  group = data.azuredevops_group.core_project_project_administrators.descriptor
  members = [
    data.azuredevops_service_principal.main.descriptor,
  ]
  mode = "add"
}
