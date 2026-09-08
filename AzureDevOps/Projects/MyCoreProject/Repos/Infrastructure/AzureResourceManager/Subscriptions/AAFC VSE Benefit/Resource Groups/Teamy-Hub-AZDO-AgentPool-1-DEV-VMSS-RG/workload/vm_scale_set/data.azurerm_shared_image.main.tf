data "azurerm_shared_image" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  gallery_name        = data.azurerm_shared_image_gallery.main.name
  name                = "aafc-ubuntu"
}
