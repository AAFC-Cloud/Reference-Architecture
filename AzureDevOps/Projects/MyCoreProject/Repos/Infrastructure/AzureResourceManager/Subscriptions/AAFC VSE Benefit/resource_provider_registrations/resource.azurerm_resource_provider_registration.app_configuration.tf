# Subscription registration belongs to the bootstrap identity, not the workload.
resource "azurerm_resource_provider_registration" "app_configuration" {
  name = "Microsoft.AppConfiguration"
  lifecycle { prevent_destroy = true }
}
