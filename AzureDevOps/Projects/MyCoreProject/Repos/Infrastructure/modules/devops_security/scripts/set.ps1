$ErrorActionPreference = 'Stop'

$organizationUrl = $env:DEVOPS_SECURITY_ORGANIZATION_URL.TrimEnd('/')
$identityId = $env:DEVOPS_SECURITY_IDENTITY_ID
$assignments = $env:DEVOPS_SECURITY_ASSIGNMENTS_JSON | ConvertFrom-Json
$apiVersion = $env:DEVOPS_SECURITY_API_VERSION

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

$assignmentProperties = @($assignments.PSObject.Properties)
$assignmentCount = $assignmentProperties.Count
$verificationAttemptLimit = 6
$verificationDelaySeconds = 2

for ($assignmentIndex = 0; $assignmentIndex -lt $assignmentCount; $assignmentIndex++) {
  $property = $assignmentProperties[$assignmentIndex]
  $assignmentNumber = $assignmentIndex + 1
  $key = [string]$property.Name
  $desired = $property.Value
  $scope = [string]$desired.scope
  $resourceId = [string]$desired.resource_id
  $roleName = [string]$desired.role_name
  $uri = "$organizationUrl/_apis/securityroles/scopes/$scope/roleassignments/resources/$resourceId"
  $progress = "[$assignmentNumber/$assignmentCount]"

  Write-Host "$progress Setting role assignment '$key' to '$roleName'."

  $body = ConvertTo-Json -InputObject @(
    [ordered]@{
      userId   = $identityId
      roleName = $roleName
    }
  ) -Compress
  $bodyFile = New-TemporaryFile

  try {
    Set-Content -LiteralPath $bodyFile -Encoding utf8 -Value $body

    az rest `
      --method put `
      --resource 499b84ac-1321-427f-aa17-267ca6975798 `
      --uri $uri `
      --uri-parameters "api-version=$apiVersion" `
      --headers "Content-Type=application/json" `
      --body "@$bodyFile" `
      --only-show-errors `
      --output none
    if ($LASTEXITCODE -ne 0) {
      throw "$progress Role assignment PUT failed for '$key' on scope '$scope' and resource '$resourceId'."
    }
  }
  finally {
    Remove-Item -LiteralPath $bodyFile -Force -ErrorAction SilentlyContinue
  }

  for ($verificationAttempt = 1; $verificationAttempt -le $verificationAttemptLimit; $verificationAttempt++) {
    $verifyRaw = az rest `
      --method get `
      --resource 499b84ac-1321-427f-aa17-267ca6975798 `
      --uri $uri `
      --uri-parameters "api-version=$apiVersion" `
      --only-show-errors `
      --output json
    if ($LASTEXITCODE -ne 0) {
      throw "$progress Role assignment verification GET failed for '$key'."
    }

    $verifyResponse = $verifyRaw | ConvertFrom-Json
    $verifyAssignments = @(Get-RoleAssignmentsFromResponse -Response $verifyResponse)
    $identityAssignments = @($verifyAssignments | Where-Object {
      $null -ne $_ -and
      [string]::Equals(
        [string]$_.identity.id,
        $identityId,
        [System.StringComparison]::OrdinalIgnoreCase
      )
    })
    $matching = @($identityAssignments | Where-Object {
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

    if ($matching.Count -gt 0) {
      Write-Host "$progress Verified role assignment '$key' on attempt $verificationAttempt/$verificationAttemptLimit."
      break
    }

    if ($verificationAttempt -eq $verificationAttemptLimit) {
      $observedRoles = @(
        $identityAssignments |
          ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace([string]$_.role.name)) {
              [string]$_.role.name
            }
            elseif (-not [string]::IsNullOrWhiteSpace([string]$_.role.displayName)) {
              [string]$_.role.displayName
            }
          } |
          Sort-Object -Unique
      )
      $observedRoleSummary = if ($observedRoles.Count -eq 0) {
        'none'
      }
      else {
        $observedRoles -join ', '
      }

      throw "$progress Role assignment verification failed for '$key' on scope '$scope' and resource '$resourceId' after $verificationAttemptLimit attempts. Observed roles for the identity: $observedRoleSummary."
    }

    Write-Host "$progress Verification attempt $verificationAttempt/$verificationAttemptLimit has not observed '$roleName'; retrying in $verificationDelaySeconds seconds."
    Start-Sleep -Seconds $verificationDelaySeconds
  }
}
