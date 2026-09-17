terraform {
  required_version = ">= 1.8.0"
  backend "azurerm" {
    resource_group_name  = "CACN-Terraform-PROD-RG"
    storage_account_name = "terraformproddwvc87"
    container_name       = "statefiles"
    key                  = "Reference-Architecture/MyCoreProject/Infrastructure/AzureDevOps/Projects/MyFirstWorkload/service_connections/workload/devops_project_permissions.tfstate"
    tenant_id            = "2e831e5f-9c6e-41a7-b295-50499684ba63" # Teamy
    subscription_id      = "6cb7032f-2437-4f5e-91e8-676cb67e5444" # AAFC VSE Benefit
    use_cli              = true
    use_azuread_auth     = true
  }
  required_providers {
    terraform = {
      source = "terraform.io/builtin/terraform"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 1.16.0"
    }
  }
}
