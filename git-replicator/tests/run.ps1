# Runs local Git discovery checks and a Terraform plan with mocked Azure DevOps.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$replicatorRoot = Split-Path $PSScriptRoot -Parent
$scratchRoot = [System.IO.Path]::GetFullPath((Join-Path $replicatorRoot '.terraform'))
$fixtureRoot = Join-Path $scratchRoot "replication-tests-$([guid]::NewGuid())"
$discoveryScript = Join-Path $replicatorRoot 'discover-repositories.ps1'

function Write-Fixture {
    param([string] $Path, [string] $Content)
    $fullPath = Join-Path $fixtureRoot $Path
    New-Item -ItemType Directory -Path (Split-Path $fullPath -Parent) -Force | Out-Null
    [System.IO.File]::WriteAllText($fullPath, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Read-Catalog {
    $query = @{ source_root = $fixtureRoot } | ConvertTo-Json -Compress
    $result = $query | & pwsh -NoLogo -NoProfile -NonInteractive -File $discoveryScript
    if ($LASTEXITCODE -ne 0) { throw 'Discovery failed for a valid fixture.' }
    $catalog = $result | ConvertFrom-Json
    return @{
        repositories = $catalog.repositories | ConvertFrom-Json -AsHashtable
        files        = $catalog.files | ConvertFrom-Json -AsHashtable
    }
}

function Assert-DiscoveryFails {
    param([string] $ExpectedMessage)
    $query = @{ source_root = $fixtureRoot } | ConvertTo-Json -Compress
    $result = $query | & pwsh -NoLogo -NoProfile -NonInteractive -File $discoveryScript 2>&1
    if ($LASTEXITCODE -eq 0 -or ($result -join "`n") -notmatch $ExpectedMessage) {
        throw "Expected discovery failure containing: $ExpectedMessage"
    }
}

try {
    New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
    & git -C $fixtureRoot init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Could not initialize the fixture Git repository.' }

    $repoA = 'AzureDevOps/Projects/Project A/Repos/Infrastructure'
    $repoB = 'AzureDevOps/Projects/Project B/Repos/Infrastructure'
    Write-Fixture '.gitignore' ".terraform/`n*.tfstate`n*.tfplan`nignore/`n*.tmp`n!keep.tmp`n"
    Write-Fixture "$repoA/README.md" "Indexed contents`n"
    Write-Fixture "$repoA/deleted.txt" "Deleted after staging`n"
    & git -C $fixtureRoot add --all
    if ($LASTEXITCODE -ne 0) { throw 'Could not stage the fixture files.' }
    Remove-Item -LiteralPath (Join-Path $fixtureRoot "$repoA/deleted.txt")
    Write-Fixture "$repoA/README.md" "Current working tree`n"
    Write-Fixture "$repoA/.terraform.lock.hcl" "# Keep provider locks`n"
    Write-Fixture "$repoA/.tfvars.pipeline_registration" "name = `"pipeline`"`n"
    Write-Fixture "$repoA/nested/space é.txt" "Unicode content: café`n"
    Write-Fixture "$repoA/keep.tmp" "Gitignore exception`n"
    Write-Fixture "$repoB/README.md" "Project B`n"
    Write-Fixture "$repoA/.terraform/provider.exe" 'Ignored cache'
    Write-Fixture "$repoA/terraform.tfstate" 'Ignored state'
    Write-Fixture "$repoA/change.tfplan" 'Ignored plan'
    Write-Fixture "$repoA/ignore/local.txt" 'Ignored local file'
    Write-Fixture "$repoA/discard.tmp" 'Ignored temporary file'
    Write-Fixture 'AzureDevOps/Projects/Project A/outside.txt' 'Outside Repos'
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'AzureDevOps/Projects/Project A/Repos/Empty') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'AzureDevOps/Projects/Empty Project/Repos/Infrastructure/nested/empty') -Force | Out-Null
    Write-Fixture 'AzureDevOps/Projects/Ignored Project/Repos/Infrastructure/terraform.tfstate' 'Ignored state only'

    $catalog = Read-Catalog
    if ($catalog.repositories.Count -ne 2 -or $catalog.files.Count -ne 6) {
        throw 'Unexpected repository/file inventory.'
    }

    # A second discovery must reflect removals from the current working tree.
    Remove-Item -LiteralPath (Join-Path $fixtureRoot "$repoB/README.md")
    $afterDelete = Read-Catalog
    if ($afterDelete.files.ContainsKey('Project B/Infrastructure/README.md') -or $afterDelete.repositories.ContainsKey('Project B/Infrastructure') -or $afterDelete.repositories.Count -ne 1) {
        throw 'Deleting the last eligible file must also omit its repository.'
    }
    Write-Fixture "$repoB/README.md" "Project B`n"

    # Raw-text uploads must fail visibly for binary input instead of corrupting it.
    $binaryPath = Join-Path $fixtureRoot "$repoA/binary.dat"
    [System.IO.File]::WriteAllBytes($binaryPath, [byte[]]@(0, 1, 2))
    Assert-DiscoveryFails 'Binary files'
    Remove-Item -LiteralPath $binaryPath
    [System.IO.File]::WriteAllBytes($binaryPath, [byte[]]@(255, 254))
    Assert-DiscoveryFails 'requires UTF-8 text'
    Remove-Item -LiteralPath $binaryPath

    # Catch an accidental git-in-git checkout even if Git would omit its contents.
    Write-Fixture "$repoA/.git" 'gitdir: missing'
    Assert-DiscoveryFails 'Nested Git repositories'
    Remove-Item -LiteralPath (Join-Path $fixtureRoot "$repoA/.git")

    & terraform "-chdir=$replicatorRoot" test -no-color "-var=source_root=$fixtureRoot"
    if ($LASTEXITCODE -ne 0) { throw 'Terraform replication tests failed.' }

    foreach ($sourceFile in $catalog.files.Values) {
        Remove-Item -LiteralPath (Join-Path $fixtureRoot $sourceFile.source_path)
    }
    $emptyCatalog = Read-Catalog
    if ($emptyCatalog.repositories.Count -ne 0 -or $emptyCatalog.files.Count -ne 0) {
        throw 'A tree with no eligible files must produce empty repository and file maps.'
    }
    Write-Output 'Passed Git discovery, exclusions, deletion, unsupported-file checks, and Terraform mapping tests.'
} finally {
    # Delete only the uniquely named fixture under this root's .terraform directory.
    $resolvedFixture = [System.IO.Path]::GetFullPath($fixtureRoot)
    $allowedPrefix = $scratchRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedFixture.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a fixture outside $scratchRoot"
    }
    if (Test-Path -LiteralPath $resolvedFixture) {
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
}
