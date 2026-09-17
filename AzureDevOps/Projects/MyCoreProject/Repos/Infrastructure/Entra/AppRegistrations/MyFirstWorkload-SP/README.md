# MyFirstWorkload deployment identity

This root follows the MyCoreProject-Bootstrap-SP application pattern: `azuread_application_registration.main`, separate application-owner resources, a service principal, and the same three output names.

Human owners are listed in [local.app_owner_object_ids.tf](./local.app_owner_object_ids.tf). The bootstrap caller is retained as an application and service-principal owner so its existing Application.ReadWrite.OwnedBy permission can maintain the identity and its federated credential.

| Output | Consumer |
| --- | --- |
| `application_client_id` | Azure DevOps service connection credentials. |
| `application_object_id` | Terraform application resource ID for the federated credential, matching the bootstrap output contract. |
| `service_principal_object_id` | Azure DevOps licensing, project permissions, Azure RBAC and state-container data access. |

The [service_connections/workload roots](<../../../AzureDevOps/Projects/MyFirstWorkload/service_connections/workload/>) and workload `core/state_file_storage_account` root consume these outputs from bootstrap remote state. Run this identity pipeline first. The connection root owns federation; this identity receives no bootstrap Microsoft Graph API permissions.
