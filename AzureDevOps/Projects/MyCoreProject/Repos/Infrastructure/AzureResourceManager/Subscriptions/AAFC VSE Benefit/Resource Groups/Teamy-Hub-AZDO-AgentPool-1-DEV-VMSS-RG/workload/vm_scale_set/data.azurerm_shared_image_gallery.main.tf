data "azurerm_shared_image_gallery" "main" {
  resource_group_name = data.azurerm_resource_group.main.name
  name                = "TEAMY_HUB_AZDO_AGENT_POOL_1_DEV_VMSS_CG"
}
