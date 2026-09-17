output "app_configuration" {
  description = "Store identity and endpoint; no access keys are exported."
  value = {
    id       = azurerm_app_configuration.main.id
    endpoint = azurerm_app_configuration.main.endpoint
  }
}
