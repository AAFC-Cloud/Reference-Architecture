Write-Host "Grabbing VM information from Terraform outputs"
$terraformOutput = terraform output -json
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read Terraform outputs.'
}
$tf_outputs = $terraformOutput | ConvertFrom-Json -ErrorAction Stop
$vm_id = $tf_outputs.vm_id.value
if ([string]::IsNullOrWhiteSpace($vm_id)) {
    throw 'Terraform output vm_id is missing. Run terraform apply first.'
}

function Invoke-InternetCheck {
    param (
        [string]$Label,
        [string]$Command
    )

    $responseJson = az vm run-command invoke `
        --ids $vm_id `
        --command-id RunShellScript `
        --scripts $Command `
        --output json `
        --only-show-errors

    if ($LASTEXITCODE -ne 0) {
        throw "Internet check '$Label' failed: Azure CLI exited with code $LASTEXITCODE."
    }

    $response = $responseJson | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $response.value -or @($response.value).Count -eq 0) {
        throw "Internet check '$Label' failed: Azure returned no status results."
    }

    foreach ($result in $response.value) {
        foreach ($line in ($result.message -split '\r\n|\n|\r')) {
            if ($line.Length -gt 0) {
                Write-Host ('{0,-6} | {1}' -f $Label, $line)
            }
        }
    }

    $failedResults = @($response.value | Where-Object { $_.code -ne 'ProvisioningState/succeeded' })
    if ($failedResults.Count -gt 0) {
        throw "Internet check '$Label' failed: expected ProvisioningState/succeeded, received $($failedResults.code -join ', ')."
    }
}

Write-Host "Ensuring the machine has a working internet connection"
Invoke-InternetCheck -Label 'vm' -Command 'curl -fsS https://official-joke-api.appspot.com/jokes/random'

Write-Host "Ensuring the machine has a working internet connection inside docker containers"
Invoke-InternetCheck -Label 'docker' -Command 'sudo docker run curlimages/curl -fsS https://official-joke-api.appspot.com/jokes/random -k'
