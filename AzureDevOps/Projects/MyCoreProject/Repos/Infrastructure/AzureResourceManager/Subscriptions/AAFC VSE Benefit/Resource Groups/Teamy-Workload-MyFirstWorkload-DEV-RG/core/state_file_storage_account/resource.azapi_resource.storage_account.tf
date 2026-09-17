resource "azapi_resource" "storage_account" {
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  name      = "teamymyfirstworkloadsa"
  parent_id = data.azurerm_resource_group.main.id
  location  = data.azurerm_resource_group.main.location
  tags      = data.azurerm_resource_group.main.tags

  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_LRS"
    }
    properties = {
      accessTier                   = "Hot"
      publicNetworkAccess          = "Enabled"
      allowCrossTenantReplication  = false
      allowBlobPublicAccess        = false
      allowSharedKeyAccess         = true
      defaultToOAuthAuthentication = false
      minimumTlsVersion            = "TLS1_2"
      supportsHttpsTrafficOnly     = true

      networkAcls = {
        for key, value in data.azapi_resource.terraform_backend_storage_account.output.properties.networkAcls :
        key => value if key != "ipv6Rules"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
