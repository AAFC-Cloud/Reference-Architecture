$ErrorActionPreference = 'Stop'

$query = [Console]::In.ReadToEnd() | ConvertFrom-Json
$organizationUrl = ([string]$query.organization_url).TrimEnd('/')
$identityId = [string]$query.identity_id
$assignments = [string]$query.assignments_json | ConvertFrom-Json
$apiVersion = [string]$query.api_version
$states = [ordered]@{}
$changeNeeded = $false

function Get-RoleAssignmentsFromResponse {
  param(
    [AllowNull()]
    [object]$Response
  )

  if ($null -eq $Response) {
    return
  }

  $valueProperty = $Response.PSObject.Properties['value']
  if ($null -ne $valueProperty) {
    @($valueProperty.Value) | Write-Output
    return
  }

  @($Response) | Write-Output
}

foreach ($property in $assignments.PSObject.Properties) {
  $key = [string]$property.Name
  $desired = $property.Value
  $scope = [string]$desired.scope
  $resourceId = [string]$desired.resource_id
  $roleName = [string]$desired.role_name
  $uri = "$organizationUrl/_apis/securityroles/scopes/$scope/roleassignments/resources/$resourceId"

  $raw = az rest `
    --method get `
    --resource 499b84ac-1321-427f-aa17-267ca6975798 `
    --uri $uri `
    --uri-parameters "api-version=$apiVersion" `
    --only-show-errors `
    --output json
  if ($LASTEXITCODE -ne 0) {
    throw "Role assignment lookup failed for '$key' on scope '$scope' and resource '$resourceId'."
  }

  $response = $raw | ConvertFrom-Json
  $responseAssignments = @(Get-RoleAssignmentsFromResponse -Response $response)
  $identityAssignments = @($responseAssignments | Where-Object {
    $null -ne $_ -and [string]::Equals(
      [string]$_.identity.id,
      $identityId,
      [System.StringComparison]::OrdinalIgnoreCase
    )
  })
  $matchingAssignments = @($identityAssignments | Where-Object {
    [string]::Equals(
      [string]$_.role.name,
      $roleName,
      [System.StringComparison]::OrdinalIgnoreCase
    ) -or [string]::Equals(
      [string]$_.role.displayName,
      $roleName,
      [System.StringComparison]::OrdinalIgnoreCase
    )
  })

  $assignment = if ($matchingAssignments.Count -gt 0) {
    $matchingAssignments[0]
  }
  elseif ($identityAssignments.Count -gt 0) {
    $identityAssignments[0]
  }
  else {
    $null
  }

  $matches = $matchingAssignments.Count -gt 0
  if (-not $matches) {
    $changeNeeded = $true
  }

  $states[$key] = [ordered]@{
    scope             = $scope
    resource_id       = $resourceId
    desired_role_name = $roleName
    exists            = $null -ne $assignment
    current_role_name = if ($null -eq $assignment) { '' } else { [string]$assignment.role.name }
    matches           = $matches
  }
}

@{
  change_needed      = $changeNeeded.ToString().ToLowerInvariant()
  current_state_json = $states | ConvertTo-Json -Compress -Depth 10
} | ConvertTo-Json -Compress
