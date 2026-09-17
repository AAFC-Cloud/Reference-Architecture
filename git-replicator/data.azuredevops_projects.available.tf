data "azuredevops_projects" "available" {
  count = length(local.project_names) > 0 ? 1 : 0

  # A project may be described in source before Core provisions it.
  state = "wellFormed"
}
