resource "azuredevops_group_membership" "project_readers" {
  for_each = data.azuredevops_group.project_readers

  group = each.value.descriptor
  members = [
    data.azuredevops_service_principal.pipeline_identity.descriptor,
  ]
  mode = "add"
}
