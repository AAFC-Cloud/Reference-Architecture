data "azurerm_subscription" "main" {
  subscription_id = data.azurerm_client_config.current.subscription_id
}
