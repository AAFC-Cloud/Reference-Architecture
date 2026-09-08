resource "azuredevops_group_membership" "core_project_endpoint_administrators" {
  group = data.azuredevops_group.core_project_endpoint_administrators.descriptor
  members = [
    data.azuredevops_service_principal.main.descriptor,
  ]
  mode = "add"
}
