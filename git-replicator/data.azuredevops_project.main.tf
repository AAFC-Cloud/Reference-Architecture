data "azuredevops_project" "main" {
  for_each = local.project_names

  name = each.value
}
