data "azuredevops_service_principal" "pipeline_identity" {
  origin_id = data.azurerm_user_assigned_identity.main.principal_id
}
