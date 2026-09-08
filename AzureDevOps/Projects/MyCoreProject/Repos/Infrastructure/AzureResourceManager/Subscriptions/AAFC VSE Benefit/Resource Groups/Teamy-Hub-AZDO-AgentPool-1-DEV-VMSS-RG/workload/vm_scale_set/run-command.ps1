<#
.SYNOPSIS
Runs a command on an instance of the Terraform-managed scale set.
.DESCRIPTION
Reads vmss_id from this module's Terraform outputs and selects the first instance
returned by Azure unless an instance is specified. The default script is echo hi.
.EXAMPLE
./run-command.ps1
.EXAMPLE
./run-command.ps1 -InstanceId 0 -Scripts 'echo hi'
.EXAMPLE
./run-command.ps1 -InstanceId 0 -Scripts 'uname -a' -VmssId '/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/virtualMachineScaleSets/<scale-set>'
#>
[CmdletBinding()]
param (
    [ValidatePattern('^\d+$')]
    [string]$InstanceId,

    [Alias('Command')]
    [ValidateNotNullOrEmpty()]
    [string[]]$Scripts = @('echo hi'),

    [ValidateNotNullOrEmpty()]
    [string]$VmssId,

    [ValidateNotNullOrEmpty()]
    [string]$CommandId = 'RunShellScript'
)

$ErrorActionPreference = 'Stop'

if (-not $VmssId) {
    Write-Host 'Grabbing scale set information from Terraform outputs'
    $VmssId = terraform "-chdir=$PSScriptRoot" output -raw vmss_id
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to read the vmss_id Terraform output. Apply the Terraform output change first, or supply -VmssId.'
    }
}

if ([string]::IsNullOrWhiteSpace($VmssId)) {
    throw 'The scale set resource ID is empty. Supply -VmssId or populate the vmss_id Terraform output.'
}

$VmssId = $VmssId.Trim().TrimEnd('/')

if (-not $InstanceId) {
    # list-instances requires separate target arguments; derive them from the resource ID.
    if ($VmssId -notmatch '^/subscriptions/(?<SubscriptionId>[^/]+)/resourceGroups/(?<ResourceGroupName>[^/]+)/providers/Microsoft\.Compute/virtualMachineScaleSets/(?<Name>[^/]+)$') {
        throw "Invalid scale set resource ID: '$VmssId'."
    }

    Write-Host 'Finding a scale set instance'
    $discoveredInstanceId = az vmss list-instances `
        --subscription $Matches.SubscriptionId `
        --resource-group $Matches.ResourceGroupName `
        --name $Matches.Name `
        --query '[0].instanceId' `
        --output tsv `
        --only-show-errors
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to list scale set instances.'
    }
    if ([string]::IsNullOrWhiteSpace($discoveredInstanceId)) {
        throw "No instances were found in scale set '$VmssId'."
    }
    $InstanceId = $discoveredInstanceId.Trim()
}

$instanceResourceId = "$VmssId/virtualMachines/$InstanceId"
Write-Host "Running $CommandId on scale set instance '$InstanceId'"
az vmss run-command invoke --ids $instanceResourceId --command-id $CommandId --scripts @Scripts
if ($LASTEXITCODE -ne 0) {
    throw "Run command failed for scale set instance '$InstanceId' (Azure CLI exit code $LASTEXITCODE)."
}
