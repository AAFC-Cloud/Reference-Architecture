$ErrorActionPreference = 'Stop'

$storageAccountName = $env:RISING_EDGE_STORAGE_ACCOUNT_NAME
$blobContainerName = $env:RISING_EDGE_BLOB_CONTAINER_NAME
$fileKey = $env:RISING_EDGE_FILE_KEY

$commonArguments = @(
  '--account-name', $storageAccountName,
  '--container-name', $blobContainerName,
  '--name', $fileKey,
  '--auth-mode', 'login',
  '--only-show-errors'
)

$existsRaw = (& az storage blob exists @commonArguments --query exists --output tsv) -join "`n"
if ($LASTEXITCODE -ne 0) {
  throw "Failed to determine whether rising-edge marker '$fileKey' exists during destroy."
}

if ([System.Convert]::ToBoolean($existsRaw.Trim())) {
  & az storage blob delete @commonArguments --output none
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to delete rising-edge marker '$fileKey'."
  }
}
