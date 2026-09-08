# Shared by the read-only status check and the apply-time Git operations.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:GitAuthHeader = $null

function Invoke-ReplicatorGit {
    param(
        [string[]] $Arguments,
        [string] $InputText,
        [int[]] $AllowedExitCodes = @(0),
        [string] $RemoteUrl
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new('git')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $startInfo.StandardInputEncoding = [System.Text.UTF8Encoding]::new($false)
    $startInfo.Environment['GIT_TERMINAL_PROMPT'] = '0'
    # A parent Git process must not redirect operations into the outer checkout.
    foreach ($key in @('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR')) {
        $startInfo.Environment.Remove($key) | Out-Null
    }
    if ($RemoteUrl -match '^https://(?:[^/]*@)?(?:dev\.azure\.com|[^/]+\.visualstudio\.com)/') {
        if (-not $script:GitAuthHeader) {
            if ($env:AZDO_PERSONAL_ACCESS_TOKEN) {
                $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(':' + $env:AZDO_PERSONAL_ACCESS_TOKEN))
                $script:GitAuthHeader = 'Authorization: Basic ' + $encoded
            } elseif ($env:SYSTEM_ACCESSTOKEN) {
                $script:GitAuthHeader = 'Authorization: Bearer ' + $env:SYSTEM_ACCESSTOKEN
            } else {
                $token = & az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken --output tsv
                if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
                    throw 'Unable to authenticate Git to Azure DevOps. Sign in with az login or set AZDO_PERSONAL_ACCESS_TOKEN.'
                }
                $script:GitAuthHeader = 'Authorization: Bearer ' + $token.Trim()
            }
        }
        # Keep credentials out of command arguments, Terraform state and .git/config.
        $startInfo.Environment['REPLICATOR_GIT_AUTH'] = $script:GitAuthHeader
        $startInfo.ArgumentList.Add('--config-env=http.extraHeader=REPLICATOR_GIT_AUTH')
    }
    foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }
    $process = [System.Diagnostics.Process]::Start($startInfo)
    try {
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if ($InputText) { $process.StandardInput.Write($InputText) }
        $process.StandardInput.Close()
        $process.WaitForExit()
        $output = $stdout.GetAwaiter().GetResult()
        $errorText = $stderr.GetAwaiter().GetResult()
        if ($process.ExitCode -notin $AllowedExitCodes) {
            throw "Git failed (exit $($process.ExitCode)): $errorText"
        }
        return [pscustomobject]@{ Output = $output; ExitCode = $process.ExitCode }
    } finally {
        $process.Dispose()
    }
}

function Get-ManifestHash {
    param([string] $Json)
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Json))).ToLowerInvariant()
}

function Assert-CachePath {
    param([string] $Path)
    $cacheRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path $PSScriptRoot -Parent) '.terraform'))
    $fullPath = [IO.Path]::GetFullPath($Path)
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if (-not $fullPath.StartsWith($cacheRoot + [IO.Path]::DirectorySeparatorChar, $comparison)) {
        throw "Refusing to use a clone outside the replicator cache: $fullPath"
    }
    $current = $fullPath
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Refusing to follow a symbolic link or junction: $current"
            }
        }
        $current = [IO.Path]::GetDirectoryName($current)
    }
    return $fullPath
}

function Assert-Manifest {
    param([System.Collections.IDictionary] $Manifest)
    $clonePath = Assert-CachePath $Manifest.clone_path
    if ($Manifest.branch -ne 'refs/heads/main') { throw 'The replicator manages refs/heads/main only.' }
    if ([string]::IsNullOrWhiteSpace($Manifest.remote_url)) { throw 'The repository remote_url is missing.' }
    foreach ($path in $Manifest.files.Keys) {
        if ([IO.Path]::IsPathRooted($path) -or $path.Contains('\') -or $path.Contains(':')) {
            throw "Invalid repository path: $path"
        }
        foreach ($segment in $path.Split('/')) {
            if ($segment -in @('', '.', '..', '.git')) { throw "Invalid repository path: $path" }
        }
        if ($Manifest.files[$path].sha256 -notmatch '^[0-9a-f]{64}$' -or $Manifest.files[$path].mode -notin @('100644', '100755')) {
            throw "Invalid file metadata: $path"
        }
    }
    return $clonePath
}

function Get-CloneEntries {
    param([string] $ClonePath)
    $files = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
    $directories = [Collections.Generic.List[string]]::new()
    $pending = [Collections.Generic.Stack[string]]::new()
    if (Test-Path -LiteralPath $ClonePath) { $pending.Push($ClonePath) }
    while ($pending.Count) {
        $directory = $pending.Pop()
        foreach ($item in Get-ChildItem -LiteralPath $directory -Force) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Refusing to follow a symbolic link or junction in a clone: $($item.FullName)"
            }
            if ($item.Name -ieq '.git') {
                if ($directory -ne $ClonePath -or -not $item.PSIsContainer) {
                    throw "Nested repositories and linked worktrees are not supported: $($item.FullName)"
                }
                continue
            }
            if ($item.PSIsContainer) {
                $directories.Add($item.FullName)
                $pending.Push($item.FullName)
            } else {
                $relative = [IO.Path]::GetRelativePath($ClonePath, $item.FullName).Replace('\', '/')
                $files.Add($relative, $item.FullName)
            }
        }
    }
    return @{ Files = $files; Directories = $directories }
}

function Assert-CloneRepository {
    param([System.Collections.IDictionary] $Manifest)
    $clonePath = $Manifest.clone_path
    $gitDirectory = Join-Path $clonePath '.git'
    if (-not (Test-Path -LiteralPath $gitDirectory -PathType Container)) { return $false }
    $topLevel = (Invoke-ReplicatorGit @('-C', $clonePath, 'rev-parse', '--show-toplevel')).Output.Trim()
    $gitCommon = (Invoke-ReplicatorGit @('-C', $clonePath, 'rev-parse', '--path-format=absolute', '--git-common-dir')).Output.Trim()
    if ([IO.Path]::GetFullPath($topLevel) -ne [IO.Path]::GetFullPath($clonePath) -or
        [IO.Path]::GetFullPath($gitCommon) -ne [IO.Path]::GetFullPath($gitDirectory)) {
        throw "The clone must have its own Git directory: $clonePath"
    }
    $origin = (Invoke-ReplicatorGit @('-C', $clonePath, 'remote', 'get-url', 'origin')).Output.Trim()
    if ($origin -cne $Manifest.remote_url) {
        throw "The cached clone has a different origin. Remove only this clone and re-plan: $clonePath"
    }
    return $true
}

function Get-RemoteHead {
    param([System.Collections.IDictionary] $Manifest)
    $result = Invoke-ReplicatorGit -Arguments @('ls-remote', '--exit-code', '--heads', $Manifest.remote_url, $Manifest.branch) -RemoteUrl $Manifest.remote_url -AllowedExitCodes @(0, 2)
    if ($result.ExitCode -eq 2) { return '' }
    if ($result.Output -notmatch '^([0-9a-f]{40,64})\s') { throw 'Git returned an invalid branch reference.' }
    return $Matches[1]
}

function Test-CloneSnapshot {
    param([System.Collections.IDictionary] $Manifest, [System.Collections.IDictionary] $Entries)
    if ($Entries.Files.Count -ne $Manifest.files.Count) { return $false }
    foreach ($path in $Manifest.files.Keys) {
        if (-not $Entries.Files.ContainsKey($path)) { return $false }
        $hash = (Get-FileHash -LiteralPath $Entries.Files[$path] -Algorithm SHA256).Hash
        if ($hash -ine $Manifest.files[$path].sha256) { return $false }
    }
    return $true
}
