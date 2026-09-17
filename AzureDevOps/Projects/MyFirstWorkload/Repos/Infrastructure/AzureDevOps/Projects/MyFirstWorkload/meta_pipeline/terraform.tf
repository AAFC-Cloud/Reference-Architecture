terraform {
  required_version = ">= 1.8.0"

  backend "azurerm" {
    tenant_id            = "2e831e5f-9c6e-41a7-b295-50499684ba63" # Teamy
    subscription_id      = "6cb7032f-2437-4f5e-91e8-676cb67e5444" # AAFC VSE Benefit
    resource_group_name  = "Teamy-Workload-MyFirstWorkload-DEV-RG"
    storage_account_name = "teamymyfirstworkloadsa"
    container_name       = "statefiles"
    key                  = "Reference-Architecture/MyFirstWorkload/Infrastructure/AzureDevOps/Projects/MyFirstWorkload/meta_pipeline.tfstate"
    use_cli              = true
    use_azuread_auth     = true
  }

  required_providers {
    azuredevops = { source = "microsoft/azuredevops", version = ">=1.16.0", }
    terraform   = { source = "terraform.io/builtin/terraform", }
  }
}
