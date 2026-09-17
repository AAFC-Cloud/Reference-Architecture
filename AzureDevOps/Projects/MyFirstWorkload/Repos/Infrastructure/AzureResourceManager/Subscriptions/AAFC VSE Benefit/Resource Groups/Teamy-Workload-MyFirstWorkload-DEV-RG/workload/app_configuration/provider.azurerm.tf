provider "azurerm" {
  subscription_id = "6cb7032f-2437-4f5e-91e8-676cb67e5444" # AAFC VSE Benefit
  tenant_id       = "2e831e5f-9c6e-41a7-b295-50499684ba63" # Teamy
  # Registered by the core bootstrap pipeline; this identity has RG-level access.
  resource_provider_registrations = "none"
  features {
    app_configuration {
      recover_soft_deleted         = false
      purge_soft_delete_on_destroy = false
    }
  }
}
