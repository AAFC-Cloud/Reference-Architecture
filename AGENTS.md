# Meta-pipeline maintenance

This repository is the reference implementation for the Terraform meta-pipeline used to discover pipeline registrations and create Azure DevOps build definitions. The Core meta-pipeline is the source of truth:

`AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/AzureDevOps/Projects/MyCoreProject/meta_pipeline`

The other meta-pipelines are separate deployments of the same pattern. Keep their shared implementation aligned with the Core directory while preserving their deployment-specific configuration.

## Configure the comparison set

`scripts/ignore/meta-pipeline-dirs.txt` is a local comparison configuration. It is intentionally under an `ignore` directory, so it is not committed by the repository's `.gitignore` rules. Put one absolute path per line in this order:

1. The Core meta-pipeline reference.
2. Each meta-pipeline to compare with it.

The first path is always the reference. Update this file when adding or removing a local checkout. Do not replace the absolute paths with relative paths or symlink-specific logic.

## Update workflow

1. Make shared changes in the Core reference first.
2. Run the drift checker before copying anything:

   ```powershell
   pwsh -NoLogo -NoProfile -File .\scripts\Compare-MetaPipelines.ps1 -NoColor
   ```

3. Review every difference. Stop if a target contains behavior that the Core reference does not have or if a project-specific file is not in the expected-drift list. Merge that behavior deliberately before synchronizing.
4. Synchronize only the reviewed shared files into the other repositories. Check each target's `git status` first so unrelated local work is not overwritten.
5. Run the drift checker again. A clean synchronization ends with `Different or missing files: 0`.

## Expected per-deployment drift

The checker ignores these files by default because they describe the repository or deployment that hosts a particular meta-pipeline:

- `data.azuredevops_git_repository.client_workloads.tf`
- `data.azuredevops_project.main.tf`
- `provider.azuredevops.tf`
- `terraform.backend.tf`
- `.tfvars.pipeline_registration`
- `azure-pipelines.yml`
- `local.repository_root.tf`
- `README.md`

`terraform.required_providers.tf` and `terraform.required_version.tf` are shared files and must remain identical. Use `-IncludeExpectedDrift` when reviewing the ignored files intentionally. Use `-IncludeIgnored` only when you also need to inspect `.terraform` caches.

The checker compares file hashes, so line endings, blank lines, and comments also need to be synchronized when the goal is byte-for-byte parity. It emits VS Code file links; use `-UseVscodeInsiders` for Insiders links.

## Validation

Run formatting and validation in every configured meta-pipeline directory:

```powershell
terraform fmt -check -diff <meta-pipeline-directory>
terraform "-chdir=<meta-pipeline-directory>" validate
```

Review the plan before applying changes, especially when a build-definition change can cause Azure DevOps to queue work during creation.
