$ErrorActionPreference = "Stop"

$vmName = $env:SOURCE_VM_NAME
$resourceGroupName = $env:SOURCE_VM_RESOURCE_GROUP_NAME
$subscriptionId = $env:AZURE_SUBSCRIPTION_ID

foreach ($requiredValue in @{
    SOURCE_VM_NAME                = $vmName
    SOURCE_VM_RESOURCE_GROUP_NAME = $resourceGroupName
    AZURE_SUBSCRIPTION_ID         = $subscriptionId
  }.GetEnumerator()) {
  if ([string]::IsNullOrWhiteSpace($requiredValue.Value)) {
    throw "Environment variable '$($requiredValue.Key)' is required."
  }
}

function Invoke-AzureCli {
  param(
    [Parameter(Mandatory)]
    [string] $Operation,

    [Parameter(Mandatory)]
    [string[]] $Arguments
  )

  Write-Host $Operation
  & az @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$Operation failed with Azure CLI exit code $LASTEXITCODE."
  }
}

Invoke-AzureCli `
  -Operation "Waiting for cloud-init to complete" `
  -Arguments @(
    "vm", "run-command", "invoke",
    "--resource-group", $resourceGroupName,
    "--name", $vmName,
    "--command-id", "RunShellScript",
    "--scripts", "cloud-init status --wait --long",
    "--subscription", $subscriptionId,
    "--only-show-errors",
    "--output", "none"
  )

# The deprovision command removes the guest agent state, so Azure Run Command
# cannot report its eventual completion. Start it asynchronously, then allow
# the guest enough time to finish before stopping the VM.
Invoke-AzureCli `
  -Operation "Starting waagent deprovisioning" `
  -Arguments @(
    "vm", "run-command", "invoke",
    "--resource-group", $resourceGroupName,
    "--name", $vmName,
    "--command-id", "RunShellScript",
    "--scripts", "sudo waagent -deprovision+user -force",
    "--subscription", $subscriptionId,
    "--no-wait",
    "--only-show-errors",
    "--output", "none"
  )

Write-Host "Waiting 60 seconds for deprovisioning to complete"
Start-Sleep -Seconds 60

Invoke-AzureCli `
  -Operation "Stopping source VM" `
  -Arguments @(
    "vm", "stop",
    "--resource-group", $resourceGroupName,
    "--name", $vmName,
    "--subscription", $subscriptionId,
    "--only-show-errors",
    "--output", "none"
  )

Invoke-AzureCli `
  -Operation "Deallocating source VM" `
  -Arguments @(
    "vm", "deallocate",
    "--resource-group", $resourceGroupName,
    "--name", $vmName,
    "--subscription", $subscriptionId,
    "--only-show-errors",
    "--output", "none"
  )

Invoke-AzureCli `
  -Operation "Generalizing source VM" `
  -Arguments @(
    "vm", "generalize",
    "--resource-group", $resourceGroupName,
    "--name", $vmName,
    "--subscription", $subscriptionId,
    "--only-show-errors",
    "--output", "none"
  )
