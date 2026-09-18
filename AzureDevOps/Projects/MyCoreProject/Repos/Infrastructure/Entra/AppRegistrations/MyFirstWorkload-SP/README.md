# MyFirstWorkload deployment identity

This root follows the MyCoreProject-Bootstrap-SP application pattern: `azuread_application_registration.main`, separate application-owner resources, a service principal, and the same three output names.

Human owners are listed in [local.app_owner_object_ids.tf](./local.app_owner_object_ids.tf). The bootstrap caller is retained as an application and service-principal owner so its existing Application.ReadWrite.OwnedBy permission can maintain the identity and its federated credential.

The import block above `azuread_application_owner.bootstrap` adopts the creator ownership that Entra already assigned to the bootstrap principal on the existing application. Its ID is derived from the application and the authenticated caller; the resource continues to explicitly manage that relationship. Run this adoption through the bootstrap service connection so the caller remains MyCoreProject-Bootstrap-SP.

This is an adoption step for the existing deployment, not an import-or-create operation. Terraform requires import IDs to be known during planning and fails if an imported relationship is absent. After successful adoption, the import block may be removed while retaining the owner resource. For a fresh deployment using this granular resource pattern, create the application first, then plan its owner resources: import relationships that already exist and create those that do not. An unconditional import cannot cover both cases in a single first-time apply. See the [Terraform import reference](https://developer.hashicorp.com/terraform/language/block/import).

| Output | Consumer |
| --- | --- |
| `application_client_id` | Azure DevOps service connection credentials. |
| `application_object_id` | Terraform application resource ID for the federated credential, matching the bootstrap output contract. |
| `service_principal_object_id` | Azure DevOps licensing, project permissions, Azure RBAC and state-container data access. |

The [service_connections/workload roots](<../../../AzureDevOps/Projects/MyFirstWorkload/service_connections/workload/>) and workload `core/state_file_storage_account` root consume these outputs from bootstrap remote state. Run this identity pipeline first. The connection root owns federation; this identity receives no bootstrap Microsoft Graph API permissions.
