terraform {
  backend "azurerm" {
    tenant_id            = "2e831e5f-9c6e-41a7-b295-50499684ba63" # Teamy
    subscription_id      = "6cb7032f-2437-4f5e-91e8-676cb67e5444" # AAFC VSE Benefit
    resource_group_name  = "CACN-Terraform-PROD-RG"
    storage_account_name = "terraformproddwvc87"
    container_name       = "statefiles"
    key                  = "Reference-Architecture/MyCoreProject/Infrastructure/AzureDevOps/Projects/MyCoreProject/service_connections/bootstrap/devops_org_permissions.tfstate"

    use_cli          = true
    use_azuread_auth = true
  }

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 1.16.0"
    }
  }
}
