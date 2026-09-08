module "devops_security" {
  source = "../../../../../../../modules/devops_security"

  identity_id = data.azuredevops_storage_key.pipeline_identity.id
  role_assignments = {
    agent_clouds = {
      scope       = "agentclouds"
      resource_id = "0"
      role_name   = "Administrator"
    }
    global_agent_pools = {
      scope       = "distributedtask.globalagentpoolrole"
      resource_id = "0"
      role_name   = "Administrator"
    }
  }

  organization_url = data.azuredevops_client_config.current.organization_url
  storage_account_id  = "/subscriptions/2e831e5f-9c6e-41a7-b295-50499684ba63/resourceGroups/CACN-Terraform-PROD-RG/providers/Microsoft.Storage/storageAccounts/terraformproddwvc87"
  blob_container_name = "statefiles"
  file_key = "Reference-Architecture/MyCoreProject/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/core/identity_devops_org_permissions.devops_security.json"
}