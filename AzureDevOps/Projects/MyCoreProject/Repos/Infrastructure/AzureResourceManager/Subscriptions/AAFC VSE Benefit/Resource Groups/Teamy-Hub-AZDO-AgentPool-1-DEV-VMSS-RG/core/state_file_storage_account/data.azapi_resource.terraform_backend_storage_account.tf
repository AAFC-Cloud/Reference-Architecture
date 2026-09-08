data "azapi_resource" "terraform_backend_storage_account" {
  type                   = "Microsoft.Storage/storageAccounts@2023-05-01"
  parent_id              = data.azurerm_resource_group.terraform_backend.id
  name                   = "terraformproddwvc87"
  response_export_values = ["properties.networkAcls"]
}
