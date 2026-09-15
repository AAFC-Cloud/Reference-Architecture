# Troubleshooting

[Français](./TROUBLESHOOTING.fr_ca.md) | [Architecture overview](./README.md) | [Reference maintenance](./MAINTENANCE.md)

For a pipeline failure, record the run number, failing step, Terraform root, and service connection used by that step. A successful local command can use a different identity or network path than the agent.

The [healthcheck pipeline][healthcheck] checks installed tools, Docker, Azure DevOps reachability, Azure authentication, and blob listing. It does not apply Terraform.

## Azure DevOps provider reports `No valid credentials found`

Check the `provider.azuredevops.tf` organization URL and which identity is authenticating. For a local run, the repository supports supplying a personal access token through the environment:

```powershell
$env:AZDO_PERSONAL_ACCESS_TOKEN = Read-Host -MaskInput 'Azure DevOps PAT'
```

Use PowerShell 7 for this prompt. The token's identity needs the permissions required by the target root. Keep the token out of Terraform files and logs, and remove the session variable when finished:

```powershell
Remove-Item Env:AZDO_PERSONAL_ACCESS_TOKEN
```

In a pipeline, verify the selected service connection and its Azure DevOps permissions. Azure subscription access alone does not establish that the identity can manage Azure DevOps resources. The [shared template][template] supplies the job token environment variables for workload identity federation.

## Pipeline registration validation fails

The [meta-pipeline][meta] reports each affected YAML file with its expected and actual values. Check the files it names:

- `yaml_path = "./azure-pipelines.yml"` resolves beside the registration file.
- Each YAML file must have only one registration.
- `trigger.paths.include` must contain the pipeline directory followed by `/**` or `/*`. A broader parent-directory wildcard does not satisfy the current validator.
- `extends.parameters.pathInRepo`, when present, must equal that directory.
- Paths are relative to the destination Azure DevOps repository. For `Infrastructure`, omit the outer `AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/` prefix.

Also supply the shared template's required `agentPoolName`, `serviceConnectionName`, and `environmentName`. The registration needs matching `queue`, `endpoint`, and `environment` authorizations. The metadata precondition checks paths and duplicates; it does not verify every template parameter.

After fixing the source, publish it with `git-replicator` and run the meta-pipeline again.

## A pipeline is missing, disabled, or waiting

A YAML file needs a `.tfvars.pipeline_registration` file and a successful meta-pipeline apply before its definition exists. Check that the registration was published and that `enabled` is absent or `true`.

For an authorization error, confirm that the named agent queue, service connection, and environment exist, then check the registration's authorizations. For a queued job, inspect agent availability in the configured pool. Initial setup must use a workstation or an existing agent until the new pool is available.

An Apply stage may be waiting for the environment's approval checks. Review the `terraform-plan` artifact. A plan with no changes intentionally skips Apply.

## Terraform state access fails or storage reports network rules

When using `--auth-mode login`, the caller needs a blob data role, such as `Storage Blob Data Contributor`, at the container or an enclosing scope. An Azure management role such as Owner does not itself grant blob data access through Microsoft Entra ID. See [Azure blob data roles](https://learn.microsoft.com/en-us/azure/storage/blobs/assign-azure-role-data-access).

Run these read-only checks from the environment that is failing, using the same identity. Set the account to the one in that root's backend; the example checks workload state:

```powershell
$subscription = 'AAFC VSE Benefit'
$storageAccount = 'teamyhubazdoagentpool1sa'

az account show --subscription $subscription --query '{subscriptionId:id,tenantId:tenantId}' --output json
az storage blob list --subscription $subscription --account-name $storageAccount --container-name statefiles --auth-mode login --num-results 1 --only-show-errors --query '[].name' --output tsv
```

`az account show` uses a management API; a successful response does not establish blob access. Check data-role assignments for the pipeline's actual identity. Have the resource owner confirm the intended subnet access without sharing the private IP allowlist. Avoid full account-property dumps, state files, or plan output that could expose those values.

The [workload storage configuration][storage] deliberately copies the prerequisite bootstrap account's network ACLs so the IP allowlist can stay out of public source. The existing agent-subnet permission is recorded from the owner's redacted example in the [maintenance guide](./MAINTENANCE.md#bringing-the-prerequisites-into-this-repository). The subnet needs a Storage service endpoint as well as the matching account rule; see [Azure Storage network access](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security).

After a prerequisite rule changes, reapply the workload storage configuration to copy it. For initial deployment, follow the [local bootstrap sequence](./MAINTENANCE.md#local-bootstrap-and-handover-to-the-agents): the already restricted bootstrap account requires a permitted local machine until the self-hosted pool has state access.

Public-IP allowlisting does not solve access from Azure clients in the storage account's own region; use an appropriate virtual-network rule and endpoint configuration. See [storage firewall limitations](https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security-limitations).

Bootstrap roots use `terraformproddwvc87`; workloads use `teamyhubazdoagentpool1sa`. Check the failing root's `terraform.tf`, including any remote-state lookups, rather than assuming both accounts have the same effective access.

## Azure DevOps network check returns HTTP 401 or 403

The PowerShell healthcheck sends an anonymous `HEAD` request. HTTP 401 means that the server responded and requires authentication; 403 means that access was refused.

The current step uses [`-SkipHttpErrorCheck`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest#-skiphttperrorcheck) to inspect the response. It accepts 2xx, 401, and 403 as reachability results and reports the status. Connection failures and unexpected HTTP statuses still fail the step.

This check does not verify Azure DevOps permissions. Investigate credentials and permissions when an authenticated provider or API call fails. The Bash and Docker checks use separate `curl` requests; use the failing step's log when diagnosing them.

## Marketplace image creation fails

Read the detailed `ResourcePurchaseValidationFailed` message:

| Error detail | Action |
| --- | --- |
| Terms have not been accepted | Check the publisher, offer, SKU, and plan in [`marketplace-image.json`][image]. For an image requiring a plan, review the terms through [`accept-marketplace-agreement.ps1`][accept] before accepting them. |
| Payment instrument is unsupported | The subscription could not purchase that offer. Accepting terms again does not resolve that purchase validation failure. Use an image the subscription can deploy. |

The configured image is Canonical Ubuntu 24.04 LTS (`Canonical:ubuntu-24_04-lts:server:latest`) with `plan: null`. It skips the agreement data lookup and VM purchase-plan block. The [CIS JSON file][cis-example] is an alternative example, not the active image selection.

For images with a plan, the [Terraform data source][agreement] checks that the agreement is accepted. Acceptance is performed separately by the script. [`unaccept-marketplace-agreement.ps1`][unaccept] cancels acceptance for the configured plan and subscription; check those values before using it.

## Cloud-init or a VM internet check fails

Run these commands from the [`workload/vm_image` directory][vm-image], after initializing its backend and creating the VM:

```powershell
terraform output -raw vm_id
./wait-for-cloudinit.ps1
```

The helper reads the VM resource ID from Terraform outputs, waits for cloud-init, and calls `check-vm-internet.ps1`. A missing `vm_id` means the selected state does not expose that output; check the working directory, backend, and preceding apply.

The internet script prints separate `vm | ...` and `docker | ...` messages. Inspect both stdout and stderr, including Docker image-pull output. It expects Azure Run Command results with code `ProvisioningState/succeeded`; also inspect the guest output and cloud-init's error fields.

The current Docker connectivity probes use `-k` / `--insecure`. A passing Docker probe therefore does not validate the certificate chain. For certificate errors in other commands, check trust configuration in both the host and container; [certificate references][certificates] accompany the image scripts.

## Reference repository maintenance

For [Git replication failures](./MAINTENANCE.md#git-replication-fails-or-unexpected-files-are-published), source-file selection, migration from per-file resources, or [Windows checkout path issues](./MAINTENANCE.md#windows-paths-or-directory-operations-fail), use the maintenance guide. Those procedures concern this reference monorepo and its publishing workflow.

[meta]: ./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureDevOps/Projects/MyCoreProject/meta_pipeline/
[template]: ./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/pipeline-templates/terraform-plan-and-apply/azure-pipelines.yml
[healthcheck]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/pipeline_healthcheck/azure-pipelines.yml>
[storage]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/core/state_file_storage_account/resource.azapi_resource.storage_account.tf>
[vm-image]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/>
[image]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/marketplace-image.json>
[cis-example]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/marketplace-image.cis-example.json>
[agreement]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/data.azurerm_marketplace_agreement.main.tf>
[accept]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/accept-marketplace-agreement.ps1>
[unaccept]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/unaccept-marketplace-agreement.ps1>
[certificates]: <./AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureResourceManager/Subscriptions/AAFC VSE Benefit/Resource Groups/Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-RG/workload/vm_image/cloud_init/CERTS.md>
