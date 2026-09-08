terraform {
  backend "azurerm" {
    tenant_id            = "2e831e5f-9c6e-41a7-b295-50499684ba63" # Teamy
    subscription_id      = "6cb7032f-2437-4f5e-91e8-676cb67e5444" # AAFC VSE Benefit
    resource_group_name  = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG"
    storage_account_name = "teamyhubazdoagentpool1sa"
    container_name       = "statefiles"
    key                  = "Reference-Architecture/MyCoreProject/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_scale_set.tfstate"

    use_cli          = true
    use_azuread_auth = true
  }


  required_providers {
    azuredevops = { source = "microsoft/azuredevops", version = ">=1.16.0", }
    azurerm     = { source = "hashicorp/azurerm", version = ">=5.5.0", }
    azuread     = { source = "hashicorp/azuread", version = ">=3.9.0", }
  }
}
