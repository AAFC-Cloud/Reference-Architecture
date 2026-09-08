resource "azurerm_shared_image_version" "main" {
  count               = local.current_image_version
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = data.azurerm_resource_group.main.tags

  gallery_name     = data.azurerm_shared_image_gallery.main.name
  image_name       = azurerm_shared_image.aafc_ubuntu.name
  managed_image_id = data.azapi_resource.source_vm.id

  name = "0.${local.current_image_version}.0"

  target_region {
    name                   = data.azurerm_resource_group.main.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }

  depends_on = [terraform_data.prepare_source_vm]
}
