data "azuredevops_storage_key" "bootstrap" {
  descriptor = data.azuredevops_service_principal.bootstrap.descriptor
}
