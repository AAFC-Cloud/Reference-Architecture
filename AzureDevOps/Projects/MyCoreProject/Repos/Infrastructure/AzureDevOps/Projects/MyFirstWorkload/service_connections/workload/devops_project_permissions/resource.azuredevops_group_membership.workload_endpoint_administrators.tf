resource "azuredevops_group_membership" "workload_endpoint_administrators" {
  group = data.azuredevops_group.workload_endpoint_administrators.descriptor
  members = [
    data.azuredevops_service_principal.main.descriptor,
  ]
  mode = "add"
}
