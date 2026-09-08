# Read-only Terraform external data source: one remote branch lookup per repository.
. (Join-Path $PSScriptRoot 'git-common.ps1')

try {
    $query = [Console]::In.ReadToEnd() | ConvertFrom-Json -AsHashtable
    $manifest = $query.manifest_json | ConvertFrom-Json -AsHashtable
    $clonePath = Assert-Manifest $manifest
    $entries = Get-CloneEntries $clonePath
    $hasClone = Assert-CloneRepository $manifest
    $remoteHead = Get-RemoteHead $manifest
    $manifestHash = Get-ManifestHash $query.manifest_json
    $marker = $null
    $markerPath = Join-Path $clonePath '.git/replicator-sync.json'
    if (Test-Path -LiteralPath $markerPath) {
        try { $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json -AsHashtable } catch { $marker = $null }
    }

    $reason = 'Local clone has not been synchronized.'
    $token = [guid]::NewGuid().ToString()
    if ($hasClone -and $marker -and $marker['manifest_hash'] -eq $manifestHash -and
        $marker['remote_head'] -eq $remoteHead -and $marker['sync_token']) {
        $head = (Invoke-ReplicatorGit @('-C', $clonePath, 'rev-parse', '--verify', 'HEAD')).Output.Trim()
        $status = (Invoke-ReplicatorGit @('-C', $clonePath, 'status', '--porcelain', '-z', '--untracked-files=all')).Output
        if ($head -eq $remoteHead -and -not $status -and (Test-CloneSnapshot $manifest $entries)) {
            $token = $marker.sync_token
            $reason = 'Up to date.'
        } else {
            $reason = 'Local clone differs from the desired snapshot.'
        }
    } elseif ($marker -and $marker['manifest_hash'] -ne $manifestHash) {
        $reason = 'Source inventory, file contents, or synchronization scripts changed.'
    } elseif ($marker -and $marker['remote_head'] -ne $remoteHead) {
        $reason = 'Remote main branch changed.'
    }
    @{ sync_token = $token; remote_head = $remoteHead; reason = $reason } | ConvertTo-Json -Compress
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
