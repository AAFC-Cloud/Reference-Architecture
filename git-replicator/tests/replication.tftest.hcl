# Run through tests/run.ps1, which supplies a temporary Git source_root.
# Azure DevOps is mocked; the filesystem/Git discovery runs for real.
mock_provider "azuredevops" {}

# Do not contact a real remote during the mapping tests.
override_data {
  target = data.external.repository_status
  values = {
    result = { sync_token = "fixture-token", remote_head = "", reason = "Fixture" }
  }
}

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
    condition = toset(keys(local_file.main)) == toset([
      "Project A/Infrastructure/README.md",
      "Project A/Infrastructure/.terraform.lock.hcl",
      "Project A/Infrastructure/.tfvars.pipeline_registration",
      "Project A/Infrastructure/nested/space é.txt",
      "Project A/Infrastructure/keep.tmp",
      "Project A/Infrastructure/binary.dat",
      "Project B/Infrastructure/README.md",
    ])
    error_message = "Replicate source files and dotfiles while excluding ignored artifacts and deleted files."
  }

  assert {
    condition = (
      base64decode(local_file.main["Project A/Infrastructure/README.md"].content_base64) == "Current working tree\n" &&
      base64decode(local_file.main["Project B/Infrastructure/README.md"].content_base64) == "Project B\n" &&
      endswith(local_file.main["Project A/Infrastructure/nested/space é.txt"].filename, "/.terraform/repos/Project A/Infrastructure/nested/space é.txt") &&
      local_file.main["Project A/Infrastructure/binary.dat"].content_base64 == "AAEC//4="
    )
    error_message = "Preserve text/binary bytes and map each source file to its own project's clone."
  }

  assert {
    condition = alltrue([
      for repository in azuredevops_git_repository.main :
      repository.default_branch == "refs/heads/main" && repository.initialization[0].init_type == "Clean"
    ])
    error_message = "Repositories need an initialized main branch before files can be added."
  }

  assert {
    condition = (
      toset(keys(terraform_data.publish)) == toset(keys(azuredevops_git_repository.main)) &&
      toset(keys(terraform_data.prepare)) == toset(keys(azuredevops_git_repository.main))
    )
    error_message = "Prepare and publish once per repository, rather than per file."
  }
}
