$ErrorActionPreference = 'Stop'

$organizationUrl = $env:DEVOPS_SECURITY_ORGANIZATION_URL.TrimEnd('/')
$identityId = $env:DEVOPS_SECURITY_IDENTITY_ID
$assignments = $env:DEVOPS_SECURITY_ASSIGNMENTS_JSON | ConvertFrom-Json
$apiVersion = $env:DEVOPS_SECURITY_API_VERSION
$removedResources = @{}

foreach ($property in $assignments.PSObject.Properties) {
  $desired = $property.Value
  $scope = [string]$desired.scope
  $resourceId = [string]$desired.resource_id
  $resourceKey = "$scope`n$resourceId"

  if ($removedResources.ContainsKey($resourceKey)) {
    continue
  }
  $removedResources[$resourceKey] = $true

  $uri = "$organizationUrl/_apis/securityroles/scopes/$scope/roleassignments/resources/$resourceId"
  $body = ConvertTo-Json -InputObject @($identityId) -Compress
  $bodyFile = New-TemporaryFile

  try {
    Set-Content -LiteralPath $bodyFile -Encoding utf8 -Value $body

    az rest `
      --method patch `
      --resource 499b84ac-1321-427f-aa17-267ca6975798 `
      --uri $uri `
      --uri-parameters "api-version=$apiVersion" `
      --headers "Content-Type=application/json" `
      --body "@$bodyFile" `
      --only-show-errors `
      --output none
    if ($LASTEXITCODE -ne 0) {
      throw "Role assignment removal failed on scope '$scope' and resource '$resourceId'."
    }
  }
  finally {
    Remove-Item -LiteralPath $bodyFile -Force -ErrorAction SilentlyContinue
  }
}
