resource "azuredevops_elastic_pool" "main" {
  name                   = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-Pool"
  service_endpoint_id    = data.azuredevops_serviceendpoint_azurerm.serviceendpoint.service_endpoint_id
  service_endpoint_scope = data.azuredevops_project.main.id
  desired_idle           = tonumber(data.external.desired_idle.result.desired_idle)
  max_capacity           = 13
  azure_resource_id      = data.azurerm_virtual_machine_scale_set.main.id

  # azure devops + vm scale sets can't be trusted to respect this in a performant manner so it was false earlier
  # takes forever for scaling up and, importantly, scaling down once agents are consumed.
  recycle_after_each_use = true
  time_to_live_minutes   = 15


  project_id     = data.azuredevops_project.main.id
  auto_provision = true # give this pool to new projects
}
