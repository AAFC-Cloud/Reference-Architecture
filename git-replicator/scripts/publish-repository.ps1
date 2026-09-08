param(
    [Parameter(Mandatory)][string] $ManifestPath,
    [Parameter(Mandatory)][string] $SyncToken
)
. (Join-Path $PSScriptRoot 'git-common.ps1')

$manifestJson = Get-Content -LiteralPath $ManifestPath -Raw
$manifest = $manifestJson | ConvertFrom-Json -AsHashtable
$clonePath = Assert-Manifest $manifest
$entries = Get-CloneEntries $clonePath
if (-not (Assert-CloneRepository $manifest)) { throw 'Prepare the local clone before publishing.' }
if (-not (Test-CloneSnapshot $manifest $entries)) {
    throw "The local files do not match the planned snapshot for $($manifest.repository_key). Re-plan and apply before publishing."
}

Invoke-ReplicatorGit @('-C', $clonePath, 'add', '--all', '--force', '--', '.') | Out-Null
# Set all index modes in one operation, preserving tracked executables on Windows.
$index = (Invoke-ReplicatorGit @('-C', $clonePath, 'ls-files', '--stage', '-z')).Output
$indexInfo = [Text.StringBuilder]::new()
$indexCount = 0
foreach ($entry in $index.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries)) {
    if ($entry -notmatch '(?s)^\d+ ([0-9a-f]+) 0\t(.+)$') { throw 'Unexpected staged Git entry.' }
    $objectId = $Matches[1]
    $path = $Matches[2]
    if (-not $manifest.files.Contains($path)) { throw "Unexpected staged file: $path" }
    $indexInfo.Append("$($manifest.files[$path].mode) $objectId").Append([char]9).Append($path).Append([char]0) | Out-Null
    $indexCount++
}
if ($indexCount -ne $manifest.files.Count) { throw 'Git did not stage every file in the manifest.' }
Invoke-ReplicatorGit -Arguments @('-C', $clonePath, 'update-index', '-z', '--index-info') -InputText $indexInfo.ToString() | Out-Null
$diff = Invoke-ReplicatorGit -Arguments @('-C', $clonePath, 'diff', '--cached', '--quiet') -AllowedExitCodes @(0, 1)
if ($diff.ExitCode -eq 1) {
    Invoke-ReplicatorGit @('-C', $clonePath, 'commit', '--quiet', '-m', 'Replicate source snapshot from Reference-Architecture') | Out-Null
    # A normal push rejects concurrent remote updates. Re-plan to retry on the new head.
    Invoke-ReplicatorGit -Arguments @('-C', $clonePath, 'push', '--porcelain', 'origin', 'HEAD:refs/heads/main') -RemoteUrl $manifest.remote_url | Out-Null
    Write-Host "$($manifest.repository_key) | Committed and pushed $($manifest.files.Count) source files in one snapshot"
} else {
    Write-Host "$($manifest.repository_key) | No content changes; no commit needed"
}

$head = (Invoke-ReplicatorGit @('-C', $clonePath, 'rev-parse', 'HEAD')).Output.Trim()
$marker = @{
    manifest_hash = Get-ManifestHash $manifestJson
    remote_head   = $head
    sync_token    = $SyncToken
} | ConvertTo-Json -Compress
$markerPath = Join-Path $clonePath '.git/replicator-sync.json'
[IO.File]::WriteAllText($markerPath, $marker, [Text.UTF8Encoding]::new($false))
