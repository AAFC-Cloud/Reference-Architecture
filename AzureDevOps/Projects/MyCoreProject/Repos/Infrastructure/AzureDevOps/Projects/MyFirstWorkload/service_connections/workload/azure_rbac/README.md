# MyFirstWorkload Azure RBAC

This follows MyCoreProject's `service_connections/bootstrap/azure_rbac` root. It grants MyFirstWorkload-SP Contributor on Teamy-Workload-MyFirstWorkload-DEV-RG.

Run the [Entra identity](<../../../../../../Entra/AppRegistrations/MyFirstWorkload-SP/>) and [resource group](<../../../../../../AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/core/resource_group/>) roots first. The role assignment uses the Entra service-principal object ID from the identity's remote-state outputs.

The resource group is looked up by name. Container data access is managed alongside the dedicated account and container in [core/state_file_storage_account](<../../../../../../AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/core/state_file_storage_account/>), matching the agent-pool storage root. The workload receives no tenant-wide role or access to the bootstrap statefiles container.
