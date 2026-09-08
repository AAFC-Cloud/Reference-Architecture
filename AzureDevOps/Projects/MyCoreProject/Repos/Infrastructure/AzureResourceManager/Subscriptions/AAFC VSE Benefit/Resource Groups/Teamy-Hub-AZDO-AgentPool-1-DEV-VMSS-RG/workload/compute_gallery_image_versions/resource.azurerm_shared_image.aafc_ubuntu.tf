resource "azurerm_shared_image" "aafc_ubuntu" {
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_shared_image_gallery.main.location
  tags                = data.azurerm_resource_group.main.tags

  gallery_name = data.azurerm_shared_image_gallery.main.name
  name         = "aafc-ubuntu"
  os_type      = "Linux"
  identifier {
    offer     = "aafc-ubuntu"
    publisher = "AAFC"
    sku       = "aafc-ubuntu"
  }
  dynamic "purchase_plan" {
    for_each = try(data.azapi_resource.source_vm.output.plan, null)[*]

    content {
      name      = purchase_plan.value.name
      product   = purchase_plan.value.product
      publisher = purchase_plan.value.publisher
    }
  }
  hyper_v_generation = "V2"
}
