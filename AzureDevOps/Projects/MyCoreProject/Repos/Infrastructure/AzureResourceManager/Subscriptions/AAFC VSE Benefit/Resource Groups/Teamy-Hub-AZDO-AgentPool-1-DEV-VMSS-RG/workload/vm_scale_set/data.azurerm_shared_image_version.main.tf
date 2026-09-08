data "azurerm_shared_image_version" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  gallery_name        = data.azurerm_shared_image_gallery.main.name
  image_name          = data.azurerm_shared_image.main.name
  name                = "0.1.0"
}
