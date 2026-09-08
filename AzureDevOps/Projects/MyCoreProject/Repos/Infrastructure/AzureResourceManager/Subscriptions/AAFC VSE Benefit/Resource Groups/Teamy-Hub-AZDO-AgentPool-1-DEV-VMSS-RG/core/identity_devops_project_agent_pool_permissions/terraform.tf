terraform {
  backend "azurerm" {
    tenant_id            = "2e831e5f-9c6e-41a7-b295-50499684ba63" # Teamy
    subscription_id      = "6cb7032f-2437-4f5e-91e8-676cb67e5444" # AAFC VSE Benefit
    resource_group_name  = "CACN-Terraform-PROD-RG"
    storage_account_name = "terraformproddwvc87"
    container_name       = "statefiles"
    key                  = "Reference-Architecture/MyCoreProject/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/core/identity_devops_project_agent_pool_permissions.tfstate"

    use_cli          = true
    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=5.0.1"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=1.9.0"
    }
    # azuread = {
    #   source  = "hashicorp/azuread"
    #   version = ">=3.1.0"
    # }
  }
}
