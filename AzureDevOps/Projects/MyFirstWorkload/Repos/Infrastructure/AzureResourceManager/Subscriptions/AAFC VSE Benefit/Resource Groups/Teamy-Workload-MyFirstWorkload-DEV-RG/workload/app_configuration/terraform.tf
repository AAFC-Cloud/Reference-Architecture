terraform {
  required_version = ">= 1.8.0"
  backend "azurerm" {
    resource_group_name  = "Teamy-Workload-MyFirstWorkload-DEV-RG"
    storage_account_name = "teamymyfirstworkloadsa"
    container_name       = "statefiles"
    key                  = "Reference-Architecture/MyFirstWorkload/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/workload/app_configuration.tfstate"
    tenant_id            = "2e831e5f-9c6e-41a7-b295-50499684ba63" # Teamy
    subscription_id      = "6cb7032f-2437-4f5e-91e8-676cb67e5444" # AAFC VSE Benefit
    use_cli              = true
    use_azuread_auth     = true
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.5.0"
    }
  }
}
