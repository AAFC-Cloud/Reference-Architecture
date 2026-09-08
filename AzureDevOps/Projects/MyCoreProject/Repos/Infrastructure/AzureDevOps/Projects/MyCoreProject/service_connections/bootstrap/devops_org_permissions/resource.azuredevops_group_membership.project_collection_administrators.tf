resource "azuredevops_group_membership" "project_collection_administrators" {
  group = data.azuredevops_group.project_collection_administrators.descriptor
  members = [
    data.azuredevops_service_principal.main.descriptor,
  ]
  mode = "add"
}
