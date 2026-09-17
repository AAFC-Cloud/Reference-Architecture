# Git replicator

This Terraform root creates Azure DevOps repositories from the directory layout
in the Reference-Architecture GitHub checkout and publishes their contents through
local Git clones, with one commit per changed repository.

```text
AzureDevOps/Projects/<project>/Repos/<repository>/<file>
                         |                  |        |
                       project         repository   path inside it
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
ignored files do not produce repository entries.

Terraform lists ready projects visible to its Azure DevOps identity and matches
them to the source inventory. Projects not yet available are deferred with a
warning and listed in the `deferred_projects` output. No repository, clone or file
operations are scheduled for those projects. Available projects publish normally.

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

Each destination's main branch mirrors the selected source files. Applies repair
drift and remove destination files absent from the source inventory, including
remote-only files and the generated README when no source README exists.
Removing a whole repository folder or its last eligible file removes it from
the desired inventory. Repository `prevent_destroy` protection rejects that plan;
retiring a managed repository requires a separate, deliberate ownership change.

The root GitHub `.gitignore` controls source selection. It is not copied into
each Azure DevOps repository automatically; put a `.gitignore` inside a
repository's source folder if that destination needs one.

## Local clones and synchronization

Clones live under the already ignored directory
`git-replicator/.terraform/repos/<project>/<repository>`.
`local_file.main` writes each selected file there using base64 content to preserve
text and binary bytes. Repository URLs come from
`azuredevops_git_repository.main[*].remote_url`.

Planning makes one Git branch lookup per repository and checks its local snapshot.
It does not fetch or push files. During apply, changed repositories are prepared
with Git initialization/fetch and an index based on the current remote main branch.
Terraform writes the local files, then Git commits all additions, edits and deletions
together and pushes normally. Unchanged snapshots create no commits.

A marker in each clone's `.git` directory records the successfully published
snapshot. Missing caches, source changes and remote or local drift schedule another
sync. A rejected push fails the apply; re-plan and apply to retry against the latest
remote head. Pushes never force-rewrite remote history.

These clones are disposable workspaces owned by the replicator. Make source edits
in the outer checkout. Git attributes and configured content filters apply when
staging; tracked executable bits are preserved, including on Windows. Symlinks,
junctions, submodules and nested source Git repositories remain unsupported.

## Prerequisites and deployment

Run from a complete Git checkout with PowerShell 7.2+ (`pwsh`), Git, and Terraform
1.8 or newer on PATH. The `source_root` variable can point to another Git
checkout; by default it is the parent of this Terraform directory.

The Azure DevOps organization is `https://dev.azure.com/teamdman/`.
This root discovers existing projects, creates their repositories and manages
local copies of files. Project creation belongs to Core's provisioning pipelines;
the replicator can publish those definitions before the new projects exist.

Use an identity with permission to create/manage repositories and contribute to
their `main` branches. Authenticate the Azure DevOps provider using your normal
provider credentials, such as `AZDO_PERSONAL_ACCESS_TOKEN`; keep credentials out
of source files. Git uses `AZDO_PERSONAL_ACCESS_TOKEN` when set, otherwise
`SYSTEM_ACCESSTOKEN`, otherwise an Azure DevOps access token from `az login`.
Tokens are passed through the child process environment and are not saved in
Terraform state or Git configuration. The Azure backend uses the authenticated Azure CLI session and
Entra ID blob access, with state key `Reference-Architecture/git-replicator.tfstate`.

From the Reference-Architecture root:

```powershell
terraform -chdir=git-replicator init
terraform -chdir=git-replicator plan -out=replication.tfplan
terraform -chdir=git-replicator apply replication.tfplan
```

Different repositories can synchronize in parallel; each has a single publishing
operation. The `repositories` output lists remote URLs, local clone paths and
managed file counts. The `deferred_projects` output lists selected projects that
were unavailable; run the replicator again after they are provisioned or access
is restored. Local file resources still appear in Terraform state, but
their refreshes are local filesystem reads rather than individual Azure API calls.

New repositories use `Clean` initialization on `refs/heads/main`. The provider
creates an initial commit. The first snapshot preserves that history and makes
the branch's file tree match the source inventory.

## Existing repositories

### Staged project onboarding

Use the normal plan/apply workflow when source includes a new project. The first
publication updates existing projects such as MyCoreProject and reports the new
project in `deferred_projects`:

```powershell
terraform -chdir=git-replicator plan -out=bootstrap-publication.tfplan
terraform -chdir=git-replicator apply bootstrap-publication.tfplan
```

Let Core's meta-pipeline register the project's provisioning pipeline, then run
that pipeline. Once the project exists, create a fresh plan and apply it to
publish the new project's repositories automatically:

```powershell
terraform -chdir=git-replicator plan -out=workload-publication.tfplan
terraform -chdir=git-replicator apply workload-publication.tfplan
```

A project can also be deferred because it is still being provisioned or is not
visible to the current identity. Check project access if a deferred project
already exists. Authentication and API failures still stop the run.

The optional `project_names` set limits the source inventory when an explicit
selection is useful. Include every project already managed by this Terraform
state. Excluding a managed repository, or losing visibility of its project, would
plan its removal and is blocked by `prevent_destroy`. Misspelled or empty
selections fail validation.

### Importing repositories

Import an existing destination repository before the first replication apply.
For example, from the Reference-Architecture root in PowerShell 7:

```powershell
terraform -chdir=git-replicator import 'azuredevops_git_repository.main["MyCoreProject/Infrastructure"]' 'MyCoreProject/Infrastructure'
```

The repository resource ignores initialization changes after creation/import
to retain existing history. Replication uses `refs/heads/main`, creating that branch
when it is absent.

Existing destination files are reconciled with the selected local contents on
the first apply.

## Migration from per-file resources

The repository resource addresses stay unchanged. The
`removed.azuredevops_git_repository_file.main.tf` block uses `destroy = false`
to forget every old `azuredevops_git_repository_file.main` instance on the next
apply without sending remote file-deletion requests. No manual state removal is
needed. Keep the block until all workspaces have migrated.

Run `terraform init` to install the local provider, then review a fresh plan. It
should show the old file resources being forgotten, new local files and Git sync
resources, and no replacement of existing repositories. Applying that plan both
migrates state and publishes the source snapshots. This includes removing any
remote-only files under the new full-mirror ownership model.

## Commits and pipelines

Each changed repository receives one commit named
`Replicate source snapshot from Reference-Architecture`. Normal Azure Pipelines
branch and path triggers apply, including for deletions. An unchanged snapshot
does not create a commit or trigger CI through a push.

This copies the current working-tree snapshot; it does not replay GitHub commit
history. Existing destination commit history is retained.

Provider references:
[`azuredevops_git_repository`](https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs/resources/git_repository)
and
[`local_file`](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file).

## Local checks

These checks do not require Azure credentials or create remote resources:

```powershell
$env:TF_DATA_DIR = "$PWD/git-replicator/.terraform/validation"
terraform -chdir=git-replicator init -backend=false
terraform -chdir=git-replicator fmt -check -recursive
terraform -chdir=git-replicator validate
pwsh -NoProfile -File git-replicator/tests/run.ps1
Remove-Item Env:TF_DATA_DIR
```

The test runner creates a temporary Git fixture inside `git-replicator/.terraform`,
exercises the real discovery script, and runs a Terraform plan with a mocked
Azure DevOps provider. Git synchronization tests use a temporary local bare remote.
The checks cover automatic deferral of unavailable projects, publication once
projects become available, case-insensitive project matching, explicit selection,
repeated repository names across projects,
omission of empty and ignored-only repositories/projects, hidden files, Git
ignore rules and exceptions, working-tree
edits/deletions, Unicode and binary files, executable bits, one-commit snapshots,
cache recovery, drift repair, no-op applies, rejected pushes and retry behavior.
