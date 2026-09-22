[CmdletBinding()]
param(
    [string] $DirectoryListPath = (Join-Path $PSScriptRoot 'ignore/meta-pipeline-dirs.txt'),
    [switch] $IncludeIgnored,
    [switch] $IncludeExpectedDrift,
    [switch] $FailOnDifference,
    [switch] $NoColor,
    [switch] $UseVscodeInsiders
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-ReportLine {
    param(
        [string] $Text,
        [ConsoleColor] $Color = [ConsoleColor]::Gray
    )

    if ($NoColor) {
        Write-Output $Text
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Get-VsCodeFileUri {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][bool] $Insiders
    )

    $absolutePath = [IO.Path]::GetFullPath($Path).Replace('\', '/')
    $scheme = if ($Insiders) { 'vscode-insiders' } else { 'vscode' }
    return "${scheme}://file/$([Uri]::EscapeUriString($absolutePath))"
}

function Write-RepositoryStatus {
    param(
        [Parameter(Mandatory)][string] $RepositoryPath,
        [Parameter(Mandatory)][string] $FilePath,
        [Parameter(Mandatory)][string] $Status,
        [Parameter(Mandatory)][ConsoleColor] $StatusColor
    )

    $text = "  ${RepositoryPath}: $Status"
    if ($NoColor) {
        Write-Output $text
    } else {
        $escape = [char]27
        $linkStart = "$escape]8;;$(Get-VsCodeFileUri -Path $FilePath -Insiders:$UseVscodeInsiders)$escape\"
        $linkEnd = "$escape]8;;$escape\"
        Write-Host "${linkStart}  $RepositoryPath$linkEnd" -ForegroundColor DarkCyan -NoNewline
        Write-Host ": $Status" -ForegroundColor $StatusColor
    }
}

function Stop-Comparison {
    param([Parameter(Mandatory)][string[]] $Message)

    foreach ($line in $Message) { Write-ReportLine -Text $line -Color Red }
    exit 1
}

function Get-FileInventory {
    param(
        [Parameter(Mandatory)][System.IO.DirectoryInfo] $Directory,
        [Parameter(Mandatory)][bool] $IncludeTerraformCache,
        [string[]] $IgnoredFileNames = @()
    )

    $inventory = @{}
    foreach ($file in Get-ChildItem -LiteralPath $Directory.FullName -Recurse -File -Force) {
        $relativePath = [IO.Path]::GetRelativePath($Directory.FullName, $file.FullName).Replace('\', '/')
        if (-not $IncludeTerraformCache -and ($relativePath -eq '.terraform' -or $relativePath.StartsWith('.terraform/'))) { continue }
        if ($relativePath -in $IgnoredFileNames) { continue }
        $inventory[$relativePath] = [pscustomobject]@{
            Hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            Path = $file.FullName
        }
    }
    return $inventory
}

function Get-CommonAncestor {
    param([Parameter(Mandatory)][string[]] $Paths)

    $candidate = Get-Item -LiteralPath $Paths[0] -Force
    while ($null -ne $candidate) {
        $candidatePath = $candidate.FullName.TrimEnd('\', '/')
        $prefix = "$candidatePath\"
        $containsAllPaths = $true
        foreach ($path in $Paths) {
            if (-not ($path.Equals($candidatePath, [StringComparison]::OrdinalIgnoreCase) -or $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase))) {
                $containsAllPaths = $false
                break
            }
        }

        if ($containsAllPaths) {
            return $candidate.FullName
        }
        $candidate = $candidate.Parent
    }

    return $null
}

function Resolve-PhysicalPath {
    param([Parameter(Mandatory)][string] $Path)

    $item = Get-Item -LiteralPath $Path -Force
    $current = $item
    while ($null -ne $current) {
        if ($current.LinkType -and $current.Target) {
            $target = @($current.Target)[0]
            if (-not [IO.Path]::IsPathRooted($target)) {
                $target = Join-Path -Path $current.Parent.FullName -ChildPath $target
            }

            $relativePath = [IO.Path]::GetRelativePath($current.FullName, $item.FullName)
            $resolvedPath = if ($relativePath -eq '.') {
                $target
            } else {
                Join-Path -Path $target -ChildPath $relativePath
            }
            return Resolve-PhysicalPath -Path ([IO.Path]::GetFullPath($resolvedPath))
        }
        $current = $current.Parent
    }

    return $item.FullName
}

if (-not (Test-Path -LiteralPath $DirectoryListPath -PathType Leaf)) {
    Stop-Comparison @(
        "Meta-pipeline comparison skipped: directory list '$DirectoryListPath' does not exist."
        'Create that file with one absolute meta-pipeline directory path per line.'
        'The first path is used as the reference directory.'
    )
}

$directoryListPath = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $DirectoryListPath).Path)
$configuredPaths = @(Get-Content -LiteralPath $directoryListPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
if ($configuredPaths.Count -lt 2) {
    Stop-Comparison @(
        "Meta-pipeline comparison skipped: '$directoryListPath' must contain at least two paths."
        'The first path is the reference; each following path is compared with it.'
    )
}

$invalidPaths = [System.Collections.Generic.List[string]]::new()
$directories = [System.Collections.Generic.List[object]]::new()
foreach ($configuredPath in $configuredPaths) {
    if (-not [IO.Path]::IsPathRooted($configuredPath)) {
        $invalidPaths.Add("Not an absolute path: $configuredPath")
        continue
    }
    if (-not (Test-Path -LiteralPath $configuredPath -PathType Container)) {
        $invalidPaths.Add("Directory does not exist: $configuredPath")
        continue
    }
    $physicalPath = Resolve-PhysicalPath -Path $configuredPath
    $resolvedDirectory = Get-Item -LiteralPath $physicalPath -Force
    $directories.Add([pscustomobject]@{
        Label = $resolvedDirectory.FullName
        Path  = $resolvedDirectory.FullName
        Item  = $resolvedDirectory
    })
}
if ($invalidPaths.Count -gt 0) {
    Stop-Comparison @(
        "Meta-pipeline comparison skipped because '$directoryListPath' contains invalid entries:"
        ($invalidPaths | ForEach-Object { "  $_" })
    )
}

$commonAncestor = Get-CommonAncestor -Paths @($directories | ForEach-Object Path)
foreach ($directory in $directories) {
    $directory.Label = if ($commonAncestor) {
        [IO.Path]::GetRelativePath($commonAncestor, $directory.Path)
    } else {
        $directory.Path
    }
}

$expectedDriftFileNames = @(
    'data.azuredevops_git_repository.client_workloads.tf'
    'data.azuredevops_project.main.tf'
    'provider.azuredevops.tf'
    'terraform.backend.tf'
    '.tfvars.pipeline_registration'
    'azure-pipelines.yml'
    'local.repository_root.tf'
    'README.md'
)
$ignoredFileNames = if ($IncludeExpectedDrift) { @() } else { $expectedDriftFileNames }
$inventories = @{}
foreach ($directory in $directories) {
    Write-Verbose "Hashing $($directory.Path)"
    $inventories[$directory.Path] = Get-FileInventory -Directory $directory.Item -IncludeTerraformCache:$IncludeIgnored -IgnoredFileNames $ignoredFileNames
}

$referenceDirectory = $directories[0]
$allPaths = @($inventories.Values | ForEach-Object Keys | Sort-Object -Unique)
$differences = [System.Collections.Generic.List[object]]::new()
foreach ($path in $allPaths) {
    $entries = foreach ($directory in $directories) {
        $entry = $inventories[$directory.Path][$path]
        [pscustomobject]@{ Directory = $directory; Hash = if ($entry) { $entry.Hash } else { $null } }
    }
    $hashes = @($entries | Where-Object Hash | Select-Object -ExpandProperty Hash -Unique)
    if ($hashes.Count -gt 1 -or @($entries | Where-Object { -not $_.Hash }).Count -gt 0) {
        $differences.Add([pscustomobject]@{ Path = $path; Entries = $entries })
    }
}

$cacheDescription = if ($IncludeIgnored) { 'including .terraform' } else { 'excluding .terraform (use -IncludeIgnored to include it)' }
Write-ReportLine "Compared $($directories.Count) meta-pipeline directories from $directoryListPath $cacheDescription." Cyan
if ($commonAncestor) {
    Write-ReportLine "Path prefix removed: $commonAncestor" DarkGray
}
Write-ReportLine "Reference: $($referenceDirectory.Label)" Yellow
Write-ReportLine "Files compared: $($allPaths.Count)" Gray
$differenceColor = if ($differences.Count -gt 0) { [ConsoleColor]::Red } else { [ConsoleColor]::Green }
Write-ReportLine "Different or missing files: $($differences.Count)" $differenceColor
if ($differences.Count -gt 0) {
    Write-ReportLine '' DarkGray
    foreach ($difference in $differences) {
        Write-ReportLine $difference.Path Magenta
        $referenceEntry = $inventories[$referenceDirectory.Path][$difference.Path]
        foreach ($entry in $difference.Entries) {
            if ($referenceEntry -and $entry.Directory.Path -eq $referenceDirectory.Path) {
                continue
            }
            if ($referenceEntry -and $entry.Hash -and $entry.Hash -eq $referenceEntry.Hash) {
                continue
            }

            $status = if (-not $entry.Hash) { 'missing' } else { 'different from reference' }
            $statusColor = if ($status -eq 'missing') { [ConsoleColor]::DarkYellow } else { [ConsoleColor]::Red }
            Write-RepositoryStatus `
                -RepositoryPath $entry.Directory.Label `
                -FilePath (Join-Path $entry.Directory.Path $difference.Path) `
                -Status $status `
                -StatusColor $statusColor
        }
    }
}
if (-not $IncludeExpectedDrift) {
    Write-ReportLine "Ignored expected per-deployment files: $($expectedDriftFileNames -join ', ') (use -IncludeExpectedDrift to include them)." DarkGray
}
if ($FailOnDifference -and $differences.Count -gt 0) { exit 1 }
