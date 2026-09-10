data "azuredevops_agent_queue" "main" {
  for_each   = local.agent_queue_names
  project_id = data.azuredevops_project.main.id
  name       = each.key
}
