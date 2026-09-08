data "azuredevops_storage_key" "agent_pool" {
  descriptor = data.azuredevops_service_principal.agent_pool.descriptor
}
