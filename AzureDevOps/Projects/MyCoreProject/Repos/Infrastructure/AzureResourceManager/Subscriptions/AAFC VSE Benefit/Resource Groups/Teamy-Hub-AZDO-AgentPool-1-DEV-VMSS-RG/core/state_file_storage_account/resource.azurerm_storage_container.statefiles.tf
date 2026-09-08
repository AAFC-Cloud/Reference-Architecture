resource "azurerm_storage_container" "statefiles" {
  storage_account_id    = azapi_resource.storage_account.id
  name                  = "statefiles"
  container_access_type = "private"
  lifecycle {
    prevent_destroy = true
  }
}
