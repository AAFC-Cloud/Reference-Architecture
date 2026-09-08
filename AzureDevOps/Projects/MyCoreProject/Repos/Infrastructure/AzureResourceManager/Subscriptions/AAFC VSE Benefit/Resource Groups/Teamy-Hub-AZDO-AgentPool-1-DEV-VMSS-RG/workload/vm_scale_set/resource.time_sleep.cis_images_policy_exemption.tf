# resource "time_sleep" "cis_images_policy_exemption" {
#   create_duration = "30s"
#   triggers = {
#     exemption_id = azurerm_resource_group_policy_exemption.cis_images.id
#   }
# }
