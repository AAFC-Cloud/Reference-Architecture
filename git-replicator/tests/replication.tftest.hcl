# Run through tests/run.ps1, which supplies a temporary Git source_root.
# Azure DevOps is mocked; the filesystem/Git discovery runs for real.
mock_provider "azuredevops" {}

override_data {
  target = data.azuredevops_project.main["Project A"]
  values = { id = "11111111-1111-1111-1111-111111111111" }
}

override_data {
  target = data.azuredevops_project.main["Project B"]
  values = { id = "22222222-2222-2222-2222-222222222222" }
}

run "replicate_repository_trees" {
  command = plan

  assert {
    condition     = toset(keys(azuredevops_git_repository.main)) == toset(["Project A/Infrastructure", "Project B/Infrastructure"])
    error_message = "Discover populated repositories while omitting empty and ignored-only repositories."
  }

  assert {
    condition     = toset(keys(data.azuredevops_project.main)) == toset(["Project A", "Project B"])
    error_message = "Projects containing only empty or ignored-only repositories must not be looked up."
  }

  assert {
    condition = (
      azuredevops_git_repository.main["Project A/Infrastructure"].project_id == "11111111-1111-1111-1111-111111111111" &&
      azuredevops_git_repository.main["Project B/Infrastructure"].project_id == "22222222-2222-2222-2222-222222222222"
    )
    error_message = "Repositories with the same name must use their own project IDs."
  }

  assert {
    condition = toset(keys(azuredevops_git_repository_file.main)) == toset([
      "Project A/Infrastructure/README.md",
      "Project A/Infrastructure/.terraform.lock.hcl",
      "Project A/Infrastructure/.tfvars.pipeline_registration",
      "Project A/Infrastructure/nested/space é.txt",
      "Project A/Infrastructure/keep.tmp",
      "Project B/Infrastructure/README.md",
    ])
    error_message = "Replicate source files and dotfiles while excluding ignored artifacts and deleted files."
  }

  assert {
    condition = (
      azuredevops_git_repository_file.main["Project A/Infrastructure/README.md"].content == "Current working tree\n" &&
      azuredevops_git_repository_file.main["Project B/Infrastructure/README.md"].content == "Project B\n" &&
      azuredevops_git_repository_file.main["Project A/Infrastructure/nested/space é.txt"].file == "nested/space é.txt"
    )
    error_message = "Read current file contents and strip only the outer project/repository prefix."
  }

  assert {
    condition = alltrue([
      for repository in azuredevops_git_repository.main :
      repository.default_branch == "refs/heads/main" && repository.initialization[0].init_type == "Clean"
    ])
    error_message = "Repositories need an initialized main branch before files can be added."
  }

  assert {
    condition = alltrue([
      for source_file in azuredevops_git_repository_file.main :
      source_file.branch == "refs/heads/main" &&
      source_file.overwrite_on_create &&
      strcontains(source_file.commit_message, "[skip ci]")
    ])
    error_message = "Manage main, adopt matching files, and skip CI for replication additions and updates."
  }
}
