$ErrorActionPreference = 'Stop'

function Get-Sha256 {
  param([Parameter(Mandatory)][string]$Value)

  $algorithm = [System.Security.Cryptography.SHA256]::Create()
  try {
    $hash = $algorithm.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Value))
    return -join ($hash | ForEach-Object { $_.ToString('x2') })
  }
  finally {
    $algorithm.Dispose()
  }
}

$query = [Console]::In.ReadToEnd() | ConvertFrom-Json
$storageAccountName = [string]$query.storage_account_name
$blobContainerName = [string]$query.blob_container_name
$fileKey = [string]$query.file_key
$risingEdge = [System.Convert]::ToBoolean([string]$query.rising_edge)

if ([string]::IsNullOrWhiteSpace($storageAccountName)) {
  throw 'storage_account_name is required.'
}
if ([string]::IsNullOrWhiteSpace($blobContainerName)) {
  throw 'blob_container_name is required.'
}
if ([string]::IsNullOrWhiteSpace($fileKey)) {
  throw 'file_key is required.'
}

$commonArguments = @(
  '--account-name', $storageAccountName,
  '--container-name', $blobContainerName,
  '--name', $fileKey,
  '--auth-mode', 'login',
  '--only-show-errors'
)

$existsRaw = (& az storage blob exists @commonArguments --query exists --output tsv) -join "`n"
if ($LASTEXITCODE -ne 0) {
  throw "Failed to determine whether rising-edge marker '$fileKey' exists."
}
$markerExists = [System.Convert]::ToBoolean($existsRaw.Trim())
$markerEtag = ''

if ($markerExists) {
  $markerEtag = ((& az storage blob show @commonArguments --query 'properties.etag || etag' --output tsv) -join "`n").Trim()
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($markerEtag)) {
    throw "Failed to read the ETag for rising-edge marker '$fileKey'."
  }

  $markerFile = [System.IO.Path]::GetTempFileName()
  try {
    & az storage blob download @commonArguments --file $markerFile --no-progress --output none
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to download rising-edge marker '$fileKey'."
    }

    $marker = Get-Content -Raw -LiteralPath $markerFile | ConvertFrom-Json
  }
  finally {
    Remove-Item -LiteralPath $markerFile -Force -ErrorAction SilentlyContinue
  }

  if ([int]$marker.schema_version -ne 1) {
    throw "Rising-edge marker '$fileKey' has an unsupported schema_version."
  }

  $committedGeneration = [string]$marker.generation
  if ($committedGeneration -notmatch '^[0-9a-f]{64}$') {
    throw "Rising-edge marker '$fileKey' contains an invalid generation."
  }

  $generation = if ($risingEdge) {
    Get-Sha256 -Value "$committedGeneration`nnext"
  }
  else {
    $committedGeneration
  }
}
else {
  # Keep plans deterministic before the marker's first apply. The file key is
  # required to be unique, so the complete marker address is a stable seed.
  $generation = Get-Sha256 -Value "initialize`n$storageAccountName`n$blobContainerName`n$fileKey"
}

@{
  generation    = [string]$generation
  marker_exists = $markerExists.ToString().ToLowerInvariant()
  marker_etag   = [string]$markerEtag
} | ConvertTo-Json -Compress
