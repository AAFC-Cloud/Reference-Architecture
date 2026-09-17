resource "azuredevops_pipeline_authorization" "main" {
  for_each    = local.pipeline_authorizations
  project_id  = data.azuredevops_project.main.id
  resource_id = each.value.resource_id
  pipeline_id = azuredevops_build_definition.main[each.value.pipeline_key].id
  type        = each.value.type
}
