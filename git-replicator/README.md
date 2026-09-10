# Git replicator

This Terraform root creates Azure DevOps repositories from the directory layout
in the Reference-Architecture GitHub checkout and manages their source files.

```text
AzureDevOps/Projects/<project>/Repos/<repository>/<file>
                         |                  |        |
                  existing project     repository   path inside it
```

For example,
`AzureDevOps/Projects/MyCoreProject/Repos/Infrastructure/Entra/example.tf`
becomes `Entra/example.tf` in the `Infrastructure` repository of
`MyCoreProject`. The repository folders stay ordinary folders in this GitHub
repository.

## Discovery and ownership

[discover-repositories.ps1](discover-repositories.ps1) examines the immediate
repository folders under each project's `Repos` directory. It uses
`git ls-files --cached --others --exclude-standard` to select files, then
Terraform reads their current working-tree contents. Only repositories with at
least one eligible file are included; empty folders and folders containing only
ignored files do not produce repositories or project lookups.

- Project names and repository names come from the directory names.
- Git-tracked files and untracked files permitted by Git's ignore rules are
  included. Ignored local state files, plans, and provider caches are excluded.
  Tracked files remain included even if a later ignore rule matches them.
- Dotfiles such as `.terraform.lock.hcl`, `.gitignore`, and
  `.tfvars.pipeline_registration` are included when selected by Git.
- Files deleted from the working tree are omitted from the desired inventory.
- Repository addresses use `<project>/<repository>`; file addresses append
  the path inside that repository. Repositories with the same name in different
  projects remain distinct.
- A file such as `.gitkeep` counts as an eligible file and enables discovery
  of an otherwise empty repository folder. Git does not preserve empty directories.

Terraform owns the selected destination files. Subsequent applies update their
contents to match this checkout, repair drift, and delete previously managed
files removed from the source inventory. Remote-only files that Terraform has
never managed are left alone. Removing a whole repository folder proposes
deleting its managed repository; review plans accordingly. Removing the last
eligible file from a previously managed repository also removes that repository
from the desired inventory and proposes deleting it.

The root GitHub `.gitignore` controls source selection. It is not copied into
each Azure DevOps repository automatically; put a `.gitignore` inside a
repository's source folder if that destination needs one.

## Prerequisites and deployment

Run from a complete Git checkout with PowerShell 7 (`pwsh`), Git, and Terraform
1.8 or newer on PATH. The `source_root` variable can point to another Git
checkout; by default it is the parent of this Terraform directory.

The Azure DevOps organization is `https://dev.azure.com/teamdman/`.
Every project with a discovered repository must already exist. `Workload1` is
omitted while its repository folders have no eligible files. This root creates
repositories and files, and looks up projects.

Use an identity with permission to create/manage repositories and contribute to
their `main` branches. Authenticate the Azure DevOps provider using your normal
provider credentials, such as `AZDO_PERSONAL_ACCESS_TOKEN`; keep credentials out
of source files. The Azure backend uses the authenticated Azure CLI session and
Entra ID blob access, with state key `Reference-Architecture/git-replicator.tfstate`.

From the Reference-Architecture root:

```powershell
terraform -chdir=git-replicator init
terraform -chdir=git-replicator plan -parallelism=1 -out=replication.tfplan
terraform -chdir=git-replicator apply -parallelism=1 replication.tfplan
```

Serial execution avoids concurrent file commits competing to update the same
branch. The plan includes each file's content changes, and the
`repositories` output lists repository URLs and managed file counts.

New repositories use `Clean` initialization on `refs/heads/main`. The provider
creates an initial commit (including its generated README); a source README
replaces it when present. Files use `overwrite_on_create = true` so matching
existing files can be brought under management.

## Existing repositories

Import an existing destination repository before the first replication apply.
For example, from the Reference-Architecture root in PowerShell 7:

```powershell
terraform -chdir=git-replicator import 'azuredevops_git_repository.main["MyCoreProject/Infrastructure"]' 'MyCoreProject/Infrastructure'
```

The repository resource ignores initialization changes after creation/import
to retain existing history. An imported repository must already have a
`refs/heads/main` branch before the file resources can write to it.

Matching destination files are adopted and overwritten with the local contents
on their first apply. Their subsequent edits and deletions are Terraform-managed.

## Commits and pipelines

The
[`azuredevops_git_repository_file` resource](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/git_repository_file)
creates a separate commit for each file operation. File additions and updates
include `[skip ci]` in the commit message to skip normal Azure Pipelines CI
triggers. Run the desired pipelines after replication completes.

The pinned Azure DevOps provider generates its own `Delete <path>` message for
file deletions and does not use `commit_message` for those operations. Deletion
commits can therefore still trigger matching pipelines.

This copies the current files, not GitHub commit history. The provider sends
file content as raw text, so the discovery script rejects non-UTF-8 files,
NUL-containing binary files, symlinks/junctions within a repository tree, and
nested Git checkouts instead of silently changing their representation. Git
executable bits, symlinks, and LFS metadata are not replicated.

This approach keeps each file reviewable in a Terraform plan and suits the
current IaC demonstration. For large or binary-heavy repositories, creating
the repositories with Terraform and publishing each directory with ordinary
Git from a temporary checkout would reduce commits and preserve Git file modes;
that also avoids nesting Git repositories in this source checkout.

Provider references:
[`azuredevops_git_repository`](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/git_repository)
and the
[file resource implementation](https://github.com/microsoft/terraform-provider-azuredevops/blob/v1.16.0/azuredevops/internal/service/git/resource_git_repository_file.go).

## Local checks

These checks do not require Azure credentials or create remote resources:

```powershell
terraform -chdir=git-replicator init -backend=false
terraform -chdir=git-replicator fmt -check -recursive
terraform -chdir=git-replicator validate
pwsh -NoProfile -File git-replicator/tests/run.ps1
```

The test runner creates a temporary Git fixture inside `git-replicator/.terraform`,
exercises the real discovery script, and runs a Terraform plan with a mocked
Azure DevOps provider. It checks repeated repository names across projects,
omission of empty and ignored-only repositories/projects, hidden files, Git
ignore rules and exceptions, working-tree
edits/deletions, Unicode paths, and rejection of unsupported inputs.
