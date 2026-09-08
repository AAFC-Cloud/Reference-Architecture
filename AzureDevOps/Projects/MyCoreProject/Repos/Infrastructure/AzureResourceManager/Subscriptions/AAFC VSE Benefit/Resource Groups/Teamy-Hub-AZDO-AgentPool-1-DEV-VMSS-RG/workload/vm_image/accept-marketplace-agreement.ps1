$subscriptionId = "6cb7032f-2437-4f5e-91e8-676cb67e5444"
$marketplaceImage = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'marketplace-image.json') -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
if ([string]::IsNullOrWhiteSpace($marketplaceImage.plan)) {
    Write-Host 'This image does not require a Marketplace agreement.'
    return
}
$imageUrn = '{0}:{1}:{2}:{3}' -f $marketplaceImage.publisher, $marketplaceImage.offer, $marketplaceImage.sku, $marketplaceImage.version

az vm image terms show --subscription $subscriptionId --urn $imageUrn
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read Marketplace agreement terms.'
}

pause
az vm image terms accept --subscription $subscriptionId --urn $imageUrn
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to accept Marketplace agreement terms.'
}
