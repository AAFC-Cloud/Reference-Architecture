# resource "azurerm_resource_group_policy_exemption" "cis_images" {
#   policy_assignment_id = data.azurerm_policy_assignment.cis_images.id
#   name                 = "${data.azurerm_resource_group.main.name} - Allow only approved CIS Images"
#   exemption_category   = "Mitigated"
#   resource_group_id    = data.azurerm_resource_group.main.id
#   description          = "We are using images from a compute gallery that are derived from CIS images, the derived images are not in the allow-list but should still be compliant."

# }
