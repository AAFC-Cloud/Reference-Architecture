data "azuredevops_storage_key" "pipeline_identity" {
  descriptor = data.azuredevops_service_principal.pipeline_identity.descriptor
}
