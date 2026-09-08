param([Parameter(Mandatory)][string] $ManifestPath)
. (Join-Path $PSScriptRoot 'git-common.ps1')

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json -AsHashtable
$clonePath = Assert-Manifest $manifest
$entries = Get-CloneEntries $clonePath
$hasClone = Assert-CloneRepository $manifest
Write-Host "$($manifest.repository_key) | Preparing local clone"

if (-not $hasClone) {
    New-Item -ItemType Directory -Path $clonePath -Force | Out-Null
    # init + fetch also works when local_file resources already created this directory.
    # No checkout/reset --hard: local_file owns the working-tree bytes.
    Invoke-ReplicatorGit @('init', '--quiet', '--initial-branch=main', $clonePath) | Out-Null
    Invoke-ReplicatorGit @('-C', $clonePath, 'remote', 'add', 'origin', $manifest.remote_url) | Out-Null
}
foreach ($setting in @{
    'core.autocrlf' = 'false'
    'core.filemode' = 'false'
    'core.hooksPath' = (Join-Path $clonePath '.git/replicator-hooks').Replace('\', '/')
    'commit.gpgSign' = 'false'
    'user.name' = 'Reference-Architecture replicator'
    'user.email' = 'git-replicator@localhost'
}.GetEnumerator()) {
    Invoke-ReplicatorGit @('-C', $clonePath, 'config', '--local', $setting.Key, $setting.Value) | Out-Null
}

$remoteHead = Get-RemoteHead $manifest
if ($remoteHead) {
    Invoke-ReplicatorGit -Arguments @('-C', $clonePath, 'fetch', '--no-tags', 'origin', '+refs/heads/main:refs/remotes/origin/main') -RemoteUrl $manifest.remote_url | Out-Null
    $base = (Invoke-ReplicatorGit @('-C', $clonePath, 'rev-parse', 'refs/remotes/origin/main')).Output.Trim()
    # Update only this disposable clone's branch and index; keep file contents intact.
    Invoke-ReplicatorGit @('-C', $clonePath, 'update-ref', 'refs/heads/main', $base) | Out-Null
    Invoke-ReplicatorGit @('-C', $clonePath, 'symbolic-ref', 'HEAD', 'refs/heads/main') | Out-Null
    Invoke-ReplicatorGit @('-C', $clonePath, 'read-tree', $base) | Out-Null
} else {
    Invoke-ReplicatorGit @('-C', $clonePath, 'update-ref', '-d', 'refs/heads/main') | Out-Null
    Invoke-ReplicatorGit @('-C', $clonePath, 'symbolic-ref', 'HEAD', 'refs/heads/main') | Out-Null
    Invoke-ReplicatorGit @('-C', $clonePath, 'read-tree', '--empty') | Out-Null
}

# The manifest owns the entire working tree. Validate the root before removing
# individual obsolete files; never traverse .git, junctions or nested checkouts.
foreach ($path in $entries.Files.Keys) {
    if (-not $manifest.files.Contains($path)) {
        Remove-Item -LiteralPath $entries.Files[$path] -Force
    }
}
foreach ($directory in ($entries.Directories | Sort-Object Length -Descending)) {
    if (-not (Get-ChildItem -LiteralPath $directory -Force | Select-Object -First 1)) {
        Remove-Item -LiteralPath $directory -Force
    }
}
