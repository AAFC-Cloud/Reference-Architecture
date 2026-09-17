resource "azuredevops_group_membership" "workload_project_administrators" {
  group = data.azuredevops_group.workload_project_administrators.descriptor
  members = [
    data.azuredevops_service_principal.main.descriptor,
  ]
  mode = "add"
}
