# MyFirstWorkload

[Français](./README.fr_ca.md)

This Azure DevOps project owns the Terraform code and deployment pipeline for its first workload: an Azure App Configuration store. The team works directly in this Infrastructure repository.

The platform project, MyCoreProject, establishes the project and its members, resource group, deployment identity, federated service connection and dedicated state storage account with a private container. This repository owns its approval environment and approvers, meta-pipeline Terraform, pipeline registrations and App Configuration deployment.

| Setting | Value |
| --- | --- |
| Resource group | `Teamy-Workload-MyFirstWorkload-DEV-RG` |
| Deployment identity | `MyFirstWorkload-SP` (Entra application and service principal) |
| Service connection | `MyFirstWorkload-ServiceConnection` |
| Approval environment | `MyFirstWorkload-DEV` |
| Agent pool | `Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-Pool` |
| State | `teamymyfirstworkloadsa` / `statefiles`, in the workload resource group |

The identity has Contributor on its resource group, Storage Blob Data Contributor on this container, and Project Administrators and Endpoint Administrators membership within MyFirstWorkload. This lets its meta-pipeline manage the project's pipeline definitions and resource authorizations. It receives no access to other projects' state or organization-wide administrator role.

Core creates the state account using the agent-pool storage pattern: matching storage settings, location and tags from the workload resource group, and network ACLs copied from the prerequisite bootstrap account at deployment time. This includes the allowed agent subnet while keeping operator IP rules out of the repository. Core grants both deployment identities blob data access on the new container. These workload roots use the resulting account without reading the bootstrap account or Core's state.

The [App Configuration root](<./AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/workload/app_configuration/>) creates a Free store in Canada Central. Its name includes a stable hash of the resource-group ID to distinguish deployments. Access-key authentication is disabled, and outputs contain only the resource ID and endpoint. Future clients need their own App Configuration data roles. Soft-deleted stores are not automatically recovered or purged by the workload identity.

Commit changes to main to run the [pipeline](<./AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Workload-MyFirstWorkload-DEV-RG/workload/app_configuration/azure-pipelines.yml>). It validates and plans Terraform, then applies the saved plan after the environment approval. The project contains its own copy of the plan-and-apply template and installer, so runs do not depend on checking out the core repository.

The [workload meta-pipeline](./AzureDevOps/Projects/MyFirstWorkload/meta_pipeline/) scans this Infrastructure repository for `.tfvars.pipeline_registration` files. It manages its own permanent definition, the [approval environment pipeline](./AzureDevOps/Projects/MyFirstWorkload/environments/Main/) and the App Configuration pipeline, including their authorizations, using its own state key in the workload container. Add registrations here as the workload grows. Core's scanner manages only Core's repository.

For local syntax checks, run the following in the App Configuration directory:

```powershell
terraform init -backend=false
terraform validate
```

These checks do not deploy resources. After Core provisions the prerequisites and the repository is published, follow the [meta-pipeline first-run procedure](./AzureDevOps/Projects/MyFirstWorkload/meta_pipeline/README.md#first-run). Apply the environment root locally once, then the meta-pipeline root to register the pipelines; subsequent changes run through this project's pipelines.
