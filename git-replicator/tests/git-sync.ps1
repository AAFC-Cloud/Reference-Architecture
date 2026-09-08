# Real local Git operations against a bare fixture remote; no Azure calls.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$replicatorRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $replicatorRoot 'scripts/git-common.ps1')
$scratchRoot = [IO.Path]::GetFullPath((Join-Path $replicatorRoot '.terraform'))
$fixture = Join-Path $scratchRoot ("git-sync-tests-" + [guid]::NewGuid())
$remote = Join-Path $fixture 'remote.git'
$seed = Join-Path $fixture 'seed'
$clone = Join-Path $fixture 'repos/Project A/Infrastructure'
$manifestPath = Join-Path $fixture 'manifest.json'
$desired = [ordered]@{
    'README.md' = [Text.Encoding]::UTF8.GetBytes("Desired README`n")
    '.gitignore' = [Text.Encoding]::UTF8.GetBytes("*.txt`n")
    'nested/space é.txt' = [Text.Encoding]::UTF8.GetBytes("Unicode café`n")
    'binary.dat' = [byte[]]@(0, 1, 2, 255, 254)
    'tools/run.sh' = [Text.Encoding]::UTF8.GetBytes("#!/bin/sh`necho test`n")
}

function Assert-Test {
    param([bool] $Condition, [string] $Message)
    if (-not $Condition) { throw $Message }
}

function Write-Manifest {
    $files = [ordered]@{}
    foreach ($path in $desired.Keys) {
        $files[$path] = @{
            sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($desired[$path])).ToLowerInvariant()
            mode = if ($path -eq 'tools/run.sh') { '100755' } else { '100644' }
        }
    }
    $manifest = @{
        repository_key = 'Project A/Infrastructure'
        clone_path = $clone
        remote_url = $remote
        branch = 'refs/heads/main'
        implementation = 'test'
        files = $files
    }
    $json = $manifest | ConvertTo-Json -Depth 10 -Compress
    [IO.File]::WriteAllText($manifestPath, $json, [Text.UTF8Encoding]::new($false))
}

function Read-SyncStatus {
    $query = @{ manifest_json = [IO.File]::ReadAllText($manifestPath) } | ConvertTo-Json -Compress
    $raw = $query | & pwsh -NoLogo -NoProfile -NonInteractive -File (Join-Path $replicatorRoot 'scripts/read-repository.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Repository status check failed.' }
    return $raw | ConvertFrom-Json
}

function Prepare-And-Write {
    & (Join-Path $replicatorRoot 'scripts/prepare-repository.ps1') -ManifestPath $manifestPath
    # Mirrors local_file.content_base64, including binary bytes.
    foreach ($path in $desired.Keys) {
        $destination = Join-Path $clone $path
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        [IO.File]::WriteAllBytes($destination, $desired[$path])
    }
}

function Publish-Snapshot {
    param([string] $Token)
    & (Join-Path $replicatorRoot 'scripts/publish-repository.ps1') -ManifestPath $manifestPath -SyncToken $Token
}

function Get-CommitCount {
    return [int](Invoke-ReplicatorGit @('--git-dir', $remote, 'rev-list', '--count', 'main')).Output.Trim()
}

function Assert-RemoteSnapshot {
    $tree = (Invoke-ReplicatorGit @('--git-dir', $remote, 'ls-tree', '-r', '--name-only', '-z', 'main')).Output
    $paths = @($tree.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries))
    Assert-Test ($paths.Count -eq $desired.Count) 'The destination tree must contain exactly the selected source files.'
    foreach ($path in $desired.Keys) {
        Assert-Test ($paths -ccontains $path) "Missing destination file: $path"
        $localBlob = (Invoke-ReplicatorGit @('-C', $clone, 'hash-object', '--no-filters', '--', $path)).Output.Trim()
        $remoteBlob = (Invoke-ReplicatorGit @('--git-dir', $remote, 'rev-parse', "main:$path")).Output.Trim()
        Assert-Test ($localBlob -eq $remoteBlob) "Destination bytes differ for $path"
    }
}

function Remove-FixtureTree {
    param([string] $Path)
    $resolved = [IO.Path]::GetFullPath($Path)
    if (-not $resolved.StartsWith($scratchRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to delete outside test cache: $resolved"
    }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}

try {
    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    Invoke-ReplicatorGit @('init', '--quiet', '--bare', '--initial-branch=main', $remote) | Out-Null
    Invoke-ReplicatorGit @('init', '--quiet', '--initial-branch=main', $seed) | Out-Null
    Invoke-ReplicatorGit @('-C', $seed, 'config', 'user.name', 'Fixture') | Out-Null
    Invoke-ReplicatorGit @('-C', $seed, 'config', 'user.email', 'fixture@localhost') | Out-Null
    [IO.File]::WriteAllText((Join-Path $seed 'remote-only.txt'), "Remove me`n")
    Invoke-ReplicatorGit @('-C', $seed, 'add', '--all') | Out-Null
    Invoke-ReplicatorGit @('-C', $seed, '-c', 'commit.gpgSign=false', 'commit', '--quiet', '-m', 'Initial remote history') | Out-Null
    Invoke-ReplicatorGit @('-C', $seed, 'remote', 'add', 'origin', $remote) | Out-Null
    Invoke-ReplicatorGit @('-C', $seed, 'push', '--quiet', 'origin', 'main') | Out-Null

    Write-Manifest
    $status = Read-SyncStatus
    Prepare-And-Write
    Publish-Snapshot $status.sync_token
    Assert-Test ((Get-CommitCount) -eq 2) 'The first snapshot must add exactly one commit.'
    Assert-RemoteSnapshot
    $mode = (Invoke-ReplicatorGit @('--git-dir', $remote, 'ls-tree', 'main', 'tools/run.sh')).Output
    Assert-Test ($mode.StartsWith('100755 ')) 'Executable bits must be preserved.'
    $message = (Invoke-ReplicatorGit @('--git-dir', $remote, 'log', '-1', '--format=%s')).Output
    Assert-Test (-not $message.Contains('[skip ci]')) 'Snapshot commits must allow normal CI triggers.'
    Write-Output 'PASS: one commit, exact mirror, binary bytes, Unicode paths, forced ignored files and executable bits'

    $unchanged = Read-SyncStatus
    Assert-Test ($unchanged.sync_token -eq $status.sync_token) 'An unchanged plan must retain its sync token.'
    Prepare-And-Write
    Publish-Snapshot $unchanged.sync_token
    Assert-Test ((Get-CommitCount) -eq 2) 'An unchanged snapshot must not add a commit.'
    Write-Output 'PASS: unchanged plan and no-op publish'

    # Exercise both file-to-directory and directory-to-file transitions.
    $desired.Remove('binary.dat')
    $desired['binary.dat/child.bin'] = [byte[]]@(3, 4, 5)
    $desired.Remove('nested/space é.txt')
    $desired['nested'] = [Text.Encoding]::UTF8.GetBytes("Now a file`n")
    Write-Manifest
    $changed = Read-SyncStatus
    Assert-Test ($changed.sync_token -ne $unchanged.sync_token) 'Source changes must schedule synchronization.'
    Prepare-And-Write
    Publish-Snapshot $changed.sync_token
    Assert-Test ((Get-CommitCount) -eq 3) 'Several additions/deletions must share one commit.'
    Assert-RemoteSnapshot
    Write-Output 'PASS: additions, deletions and file/directory transitions'

    # A fresh worker/cache must recover without adding an identical commit.
    Remove-FixtureTree $clone
    $missing = Read-SyncStatus
    Assert-Test ($missing.sync_token -ne $changed.sync_token) 'A missing clone must schedule preparation.'
    Prepare-And-Write
    Publish-Snapshot $missing.sync_token
    Assert-Test ((Get-CommitCount) -eq 3) 'Rebuilding a clone must not add a duplicate commit.'
    Assert-RemoteSnapshot
    Write-Output 'PASS: missing-cache recovery'

    # Repair local drift, including files never represented by local_file resources.
    [IO.File]::WriteAllText((Join-Path $clone 'README.md'), 'Local drift')
    [IO.File]::WriteAllText((Join-Path $clone 'extra.txt'), 'Local extra')
    $drift = Read-SyncStatus
    Assert-Test ($drift.sync_token -ne $missing.sync_token) 'Local drift must schedule synchronization.'
    Prepare-And-Write
    Publish-Snapshot $drift.sync_token
    Assert-Test ((Get-CommitCount) -eq 3) 'Repairing only local drift must not add a remote commit.'
    Write-Output 'PASS: local drift and extra-file cleanup'

    # Remote edits must be reconciled on top of the remote's current history.
    Invoke-ReplicatorGit @('-C', $seed, 'pull', '--quiet', '--ff-only', 'origin', 'main') | Out-Null
    [IO.File]::WriteAllText((Join-Path $seed 'remote-drift.txt'), 'Remote drift')
    Invoke-ReplicatorGit @('-C', $seed, 'add', '--all', '--force') | Out-Null
    Invoke-ReplicatorGit @('-C', $seed, '-c', 'commit.gpgSign=false', 'commit', '--quiet', '-m', 'Remote edit') | Out-Null
    Invoke-ReplicatorGit @('-C', $seed, 'push', '--quiet', 'origin', 'main') | Out-Null
    $remoteEdit = (Invoke-ReplicatorGit @('-C', $seed, 'rev-parse', 'HEAD')).Output.Trim()
    $remoteDrift = Read-SyncStatus
    Assert-Test ($remoteDrift.sync_token -ne $drift.sync_token) 'Remote drift must schedule synchronization.'
    Prepare-And-Write
    Publish-Snapshot $remoteDrift.sync_token
    $parent = (Invoke-ReplicatorGit @('--git-dir', $remote, 'rev-parse', 'main^')).Output.Trim()
    Assert-Test ($parent -eq $remoteEdit) 'Replication must preserve remote history.'
    Assert-RemoteSnapshot
    Write-Output 'PASS: remote drift repair preserves history'

    # Simulate a rejected push, then retry from the current remote head.
    $desired['README.md'] = [Text.Encoding]::UTF8.GetBytes("Retry snapshot`n")
    Write-Manifest
    $retry = Read-SyncStatus
    Prepare-And-Write
    $hook = Join-Path $remote 'hooks/pre-receive'
    [IO.File]::WriteAllText($hook, "#!/bin/sh`nexit 1`n", [Text.UTF8Encoding]::new($false))
    if (-not $IsWindows) { & chmod +x $hook }
    $failed = $false
    try { Publish-Snapshot $retry.sync_token } catch { $failed = $_.Exception.Message.Contains('Git failed') }
    Assert-Test $failed 'A rejected push must fail the apply.'
    Remove-Item -LiteralPath $hook
    $afterFailure = Read-SyncStatus
    Assert-Test ($afterFailure.sync_token -ne $retry.sync_token) 'A failed push must not be marked synchronized.'
    Prepare-And-Write
    Publish-Snapshot $afterFailure.sync_token
    Assert-RemoteSnapshot
    Assert-Test ((Read-SyncStatus).sync_token -eq $afterFailure.sync_token) 'A successful retry must become stable.'
    Write-Output 'PASS: rejected push and subsequent retry'

    # The publish phase cannot send an incomplete or modified planned snapshot.
    [IO.File]::WriteAllText((Join-Path $clone 'README.md'), 'Changed after plan')
    $failed = $false
    try { Publish-Snapshot 'must-not-publish' } catch { $failed = $_.Exception.Message.Contains('planned snapshot') }
    Assert-Test $failed 'Publishing changed or incomplete local contents must fail.'
    Write-Output 'PASS: snapshot verification before publication'
} finally {
    Remove-FixtureTree $fixture
}
