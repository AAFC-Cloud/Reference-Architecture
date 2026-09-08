# Azure DevOps security roles

Reconciles Azure DevOps security-role assignments that the Azure DevOps Terraform provider cannot manage reliably.

The module reads each requested `(scope, resource_id)` pair, detects missing or incorrect roles, and uses the shared `rising_edge` module to trigger one reconciliation for each observed drift event. The identity must be supplied as its Azure DevOps storage-key GUID.

Assignments passed to one module instance are one lifecycle unit: changing or destroying the instance temporarily removes the old assignments before applying the new set.

## Rationale

This module is used instead of the usual `azuredevops_` provider because the provider is stinky and doesn't work or at least doesn't map intuitively on to the actions taken in the web portal.

For example: 

- https://dev.azure.com/TeamDman/MyCoreProject/_settings/agentqueues > Security

We want to set the managed identity as Creator in that dialogue.
The azure devops provider, if we give it the `role_name = "Administrator"` and apply, it shows as User in the web interface.

Therefore, pwsh is needed to get it to actually freaking work.