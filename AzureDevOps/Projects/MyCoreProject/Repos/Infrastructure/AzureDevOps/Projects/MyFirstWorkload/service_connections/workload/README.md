# MyFirstWorkload service connections

This follows the [MyCoreProject service_connections/bootstrap layout](<../../../MyCoreProject/service_connections/bootstrap/>), with one grouping directory per connection and independently applied Terraform roots for each responsibility:

```text
service_connections/
  workload/
    azure_rbac/
    devops_license/
    devops_project_permissions/
    service_connection/
```

| Root | Responsibility | Prerequisites |
| --- | --- | --- |
| [devops_license](<devops_license/>) | Onboard MyFirstWorkload-SP into the Azure DevOps organization. | Entra identity. |
| [devops_project_permissions](<devops_project_permissions/>) | Add that principal to MyFirstWorkload's Project Administrators and Endpoint Administrators. | Project, Entra identity and Azure DevOps licensing. |
| [azure_rbac](<azure_rbac/>) | Contributor on the workload resource group. | Entra identity and resource group. |
| [service_connection](<service_connection/>) | Create the federated connection and the Entra application's federated credential. | Project and Entra identity. |

These roots run in MyCoreProject using the bootstrap connection. The [Entra application registration](<../../../../../Entra/AppRegistrations/MyFirstWorkload-SP/>) stays under Core's Entra tree. Organization-wide administration is a bootstrap responsibility; the workload does not require a `devops_org_permissions` root.

Resource creation stays in the Azure Resource Manager tree: [resource group](<../../../../../AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/core/resource_group/>), [state storage account](<../../../../../AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/core/state_file_storage_account/>) and [subscription provider registrations](<../../../../../AzureResourceManager/Subscriptions/AAFC VSE Benefit/resource_provider_registrations/>). The storage root also grants container data access to the workload and bootstrap identities. Each root has its own backend key and pipeline registration. Complete the prerequisites before running the workload's own pipelines.
