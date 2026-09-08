$ErrorActionPreference = 'Stop'

$storageAccountName = $env:RISING_EDGE_STORAGE_ACCOUNT_NAME
$blobContainerName = $env:RISING_EDGE_BLOB_CONTAINER_NAME
$fileKey = $env:RISING_EDGE_FILE_KEY
$generation = $env:RISING_EDGE_GENERATION
$markerExists = [System.Convert]::ToBoolean($env:RISING_EDGE_MARKER_EXISTS)
$markerEtag = $env:RISING_EDGE_MARKER_ETAG

if ($generation -notmatch '^[0-9a-f]{64}$') {
  throw 'RISING_EDGE_GENERATION is invalid.'
}
if ($markerExists -and [string]::IsNullOrWhiteSpace($markerEtag)) {
  throw 'RISING_EDGE_MARKER_ETAG is required when the marker exists.'
}

$markerFile = [System.IO.Path]::GetTempFileName()
try {
  [ordered]@{
    schema_version = 1
    generation     = $generation
    claimed_at_utc = [DateTimeOffset]::UtcNow.ToString('O')
  } | ConvertTo-Json | Set-Content -LiteralPath $markerFile -Encoding utf8

  $arguments = @(
    'storage', 'blob', 'upload',
    '--account-name', $storageAccountName,
    '--container-name', $blobContainerName,
    '--name', $fileKey,
    '--file', $markerFile,
    '--auth-mode', 'login',
    '--content-type', 'application/json',
    '--overwrite', 'true',
    '--no-progress',
    '--only-show-errors',
    '--output', 'none'
  )

  if ($markerExists) {
    $arguments += @('--if-match', $markerEtag)
  }
  else {
    # Keep the wildcard in the same native-command token as the option. On
    # Linux agents, a standalone * can expand to every file in the working
    # directory before Azure CLI receives it.
    $arguments += '--if-none-match=*'
  }

  & az @arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to claim rising-edge generation for marker '$fileKey'. A concurrent update may require a fresh plan."
  }

  $verificationFile = [System.IO.Path]::GetTempFileName()
  try {
    & az storage blob download `
      --account-name $storageAccountName `
      --container-name $blobContainerName `
      --name $fileKey `
      --file $verificationFile `
      --auth-mode login `
      --no-progress `
      --only-show-errors `
      --output none
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to verify rising-edge marker '$fileKey'."
    }

    $verifiedMarker = Get-Content -Raw -LiteralPath $verificationFile | ConvertFrom-Json
    if ([string]$verifiedMarker.generation -ne $generation) {
      throw "Rising-edge marker '$fileKey' does not contain the claimed generation."
    }
  }
  finally {
    Remove-Item -LiteralPath $verificationFile -Force -ErrorAction SilentlyContinue
  }
}
finally {
  Remove-Item -LiteralPath $markerFile -Force -ErrorAction SilentlyContinue
}
