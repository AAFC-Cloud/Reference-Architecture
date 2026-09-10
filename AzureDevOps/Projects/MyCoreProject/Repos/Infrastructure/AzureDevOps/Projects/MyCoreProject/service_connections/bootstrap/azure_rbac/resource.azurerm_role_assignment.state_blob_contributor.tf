resource "azurerm_role_assignment" "state_blob_contributor" {
  principal_id         = data.terraform_remote_state.bootstrap.outputs.service_principal_object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = "/subscriptions/6cb7032f-2437-4f5e-91e8-676cb67e5444/resourceGroups/CACN-Terraform-PROD-RG/providers/Microsoft.Storage/storageAccounts/terraformproddwvc87/blobServices/default/containers/statefiles"
}
