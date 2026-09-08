data "azurerm_marketplace_agreement" "main" {
  for_each = local.marketplace_image.plan != null ? { image = local.marketplace_image } : {}

  publisher = each.value.publisher
  offer     = each.value.offer
  plan      = each.value.plan

  lifecycle {
    postcondition {
      condition     = self.accepted
      error_message = "The Marketplace agreement for ${self.publisher}:${self.offer}:${self.plan} has not been accepted in this subscription. Review and accept the terms using accept-marketplace-agreement.ps1, then rerun terraform plan."
    }
  }
}
