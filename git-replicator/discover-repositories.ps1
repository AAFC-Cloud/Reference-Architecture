# Terraform external data source: one JSON object in, one JSON object out.
# Requires PowerShell 7 and Git. This script only reads the source checkout.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-Git {
    param([string[]] $Arguments)

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new('git')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    foreach ($argument in $Arguments) {
        $startInfo.ArgumentList.Add($argument)
    }
    $process = [System.Diagnostics.Process]::Start($startInfo)
    try {
        $stderr = $process.StandardError.ReadToEndAsync()
        $stdout = $process.StandardOutput.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) {
            throw "Git failed: $($stderr.GetAwaiter().GetResult())"
        }
        return $stdout
    } finally {
        $process.Dispose()
    }
}

function Assert-RegularPath {
    param([string] $Root, [string] $RelativePath)

    $currentPath = $Root
    foreach ($segment in $RelativePath.Split('/')) {
        $currentPath = Join-Path $currentPath $segment
        $item = Get-Item -LiteralPath $currentPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            throw "Symbolic links and junctions cannot be replicated as Git files: $RelativePath"
        }
    }
}

try {
    $query = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $sourceRoot = (Resolve-Path -LiteralPath $query.source_root).Path
    # A prefix check also works when the checkout is reached through a junction.
    $gitPrefix = [string](Invoke-Git -Arguments @('-C', $sourceRoot, 'rev-parse', '--show-prefix'))
    if ($gitPrefix.TrimEnd("`r", "`n").Length -ne 0) {
        throw 'source_root must be the root of the Git checkout.'
    }

    $projectsPath = Join-Path $sourceRoot 'AzureDevOps/Projects'
    if (-not (Test-Path -LiteralPath $projectsPath -PathType Container)) {
        throw 'source_root must contain AzureDevOps/Projects.'
    }

    $repositoryCandidates = [System.Collections.Generic.SortedDictionary[string, object]]::new([StringComparer]::Ordinal)
    $repositories = [System.Collections.Generic.SortedDictionary[string, object]]::new([StringComparer]::Ordinal)
    $files = [System.Collections.Generic.SortedDictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($project in (Get-ChildItem -LiteralPath $projectsPath -Directory | Sort-Object Name)) {
        $reposPath = Join-Path $project.FullName 'Repos'
        if (-not (Test-Path -LiteralPath $reposPath -PathType Container)) {
            continue
        }
        foreach ($repository in (Get-ChildItem -LiteralPath $reposPath -Directory | Sort-Object Name)) {
            $relativePath = "AzureDevOps/Projects/$($project.Name)/Repos/$($repository.Name)"
            Assert-RegularPath -Root $sourceRoot -RelativePath $relativePath
            if (Test-Path -LiteralPath (Join-Path $repository.FullName '.git')) {
                throw "Nested Git repositories are not supported: $relativePath"
            }
            $repositoryCandidates["$($project.Name)/$($repository.Name)"] = @{
                project_name    = $project.Name
                repository_name = $repository.Name
            }
        }
    }

    # Include tracked and untracked files, respecting Git's ignore rules for
    # untracked files. NUL separators preserve spaces and Unicode in paths.
    $paths = Invoke-Git -Arguments @('-C', $sourceRoot, 'ls-files', '--cached', '--others', '--exclude-standard', '-z', '--', 'AzureDevOps/Projects/')
    $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
    foreach ($sourcePath in ($paths.Split([char]0, [StringSplitOptions]::RemoveEmptyEntries) | Sort-Object -Unique -CaseSensitive)) {
        if ($sourcePath -notmatch '^AzureDevOps/Projects/([^/]+)/Repos/([^/]+)/(.+)$') {
            continue
        }
        $repositoryKey = "$($Matches[1])/$($Matches[2])"
        $repositoryPath = $Matches[3]
        $absolutePath = Join-Path $sourceRoot $sourcePath
        # Git lists tracked files deleted from the working tree; omit them so
        # Terraform can remove the corresponding managed destination files.
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            continue
        }
        Assert-RegularPath -Root $sourceRoot -RelativePath $sourcePath
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            throw "Expected a regular file, found a nested repository or directory: $sourcePath"
        }
        if (-not $repositoryCandidates.ContainsKey($repositoryKey)) {
            throw "File does not belong to a discovered repository: $sourcePath"
        }
        try {
            $content = $utf8.GetString([System.IO.File]::ReadAllBytes($absolutePath))
        } catch {
            throw "The repository-file resource requires UTF-8 text: $sourcePath"
        }
        if ($content.Contains([char]0)) {
            throw "Binary files cannot be replicated by the repository-file resource: $sourcePath"
        }
        # Only repositories with an eligible file need a repository resource
        # or a project lookup. Empty/ignored-only directory trees are omitted.
        $repositories[$repositoryKey] = $repositoryCandidates[$repositoryKey]
        $files["$repositoryKey/$repositoryPath"] = @{
            repository_key  = $repositoryKey
            repository_path = $repositoryPath
            source_path     = $sourcePath
        }
    }

    # The external provider requires string values, so encode the nested maps.
    @{
        repositories = ConvertTo-Json -InputObject $repositories -Depth 5 -Compress
        files        = ConvertTo-Json -InputObject $files -Depth 5 -Compress
    } | ConvertTo-Json -Compress
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
