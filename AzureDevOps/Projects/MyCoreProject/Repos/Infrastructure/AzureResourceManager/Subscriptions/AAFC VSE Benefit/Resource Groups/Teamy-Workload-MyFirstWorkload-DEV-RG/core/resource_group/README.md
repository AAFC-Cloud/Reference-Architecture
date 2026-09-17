# MyFirstWorkload resource group

This root follows the agent-pool's `core/resource_group` layout. It creates Teamy-Workload-MyFirstWorkload-DEV-RG in Canada Central with Development tags and deletion protection.

It runs through the Core bootstrap connection and has no dependency on the workload identity. [Azure RBAC](<../../../../../../../AzureDevOps/Projects/MyFirstWorkload/service_connections/workload/azure_rbac/>) grants the workload principal access after the group exists. The [state storage account](<../state_file_storage_account/>) is then created in this group by its own root. [Subscription provider registrations](<../../../../resource_provider_registrations/>) are managed separately.
