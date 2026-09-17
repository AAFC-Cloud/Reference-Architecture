# Run through tests/run.ps1, which supplies a temporary Git source_root.
# Azure DevOps is mocked; the filesystem/Git discovery runs for real.
mock_provider "azuredevops" {}

run "select_existing_project" {
  command = plan
  variables {
    project_names = ["Project A"]
  }
  assert {
    condition = (
      toset(keys(azuredevops_git_repository.main)) == toset(["Project A/Infrastructure"]) &&
      local.project_names == toset(["Project A"]) &&
      length(output.deferred_projects) == 0 &&
      toset(keys(terraform_data.publish)) == toset(["Project A/Infrastructure"]) &&
      toset(keys(terraform_data.prepare)) == toset(["Project A/Infrastructure"]) &&
      alltrue([for source_file in local.files : source_file.repository_key == "Project A/Infrastructure"])
    )
    error_message = "An explicit selection must only clone, write files and publish repositories in the selected project."
  }
}

run "reject_unknown_project_selection" {
  command = plan
  variables {
    project_names = ["Misspelled Project"]
  }
  expect_failures = [data.external.source]
}

# Do not contact a real remote during the mapping tests.
override_data {
  target = data.external.repository_status
  values = {
    result = { sync_token = "fixture-token", remote_head = "", reason = "Fixture" }
  }
}

override_data {
  target = data.azuredevops_projects.available
  values = {
    projects = [
      { name = "Project A", project_id = "11111111-1111-1111-1111-111111111111" },
      { name = "Project B", project_id = "22222222-2222-2222-2222-222222222222" },
    ]
  }
}

run "defer_new_project_automatically" {
  command = plan

  override_data {
    target = data.azuredevops_projects.available
    values = {
      projects = [{ name = "Project A", project_id = "11111111-1111-1111-1111-111111111111" }]
    }
  }

  expect_failures = [check.projects_available]

  assert {
    condition = (
      toset(output.deferred_projects) == toset(["Project B"]) &&
      toset(keys(azuredevops_git_repository.main)) == toset(["Project A/Infrastructure"]) &&
      toset(keys(data.external.repository_status)) == toset(["Project A/Infrastructure"]) &&
      toset(keys(local_file.manifest)) == toset(["Project A/Infrastructure"]) &&
      toset(keys(terraform_data.prepare)) == toset(["Project A/Infrastructure"]) &&
      toset(keys(terraform_data.publish)) == toset(["Project A/Infrastructure"]) &&
      length(local_file.main) == 6 &&
      !contains(keys(local_file.main), "Project B/Infrastructure/README.md")
    )
    error_message = "A missing project must be reported and deferred while the existing project's repositories and files can still publish."
  }
}

run "defer_all_projects_without_git_operations" {
  command = plan

  override_data {
    target = data.azuredevops_projects.available
    values = { projects = [] }
  }

  expect_failures = [check.projects_available]

  assert {
    condition = (
      toset(output.deferred_projects) == toset(["Project A", "Project B"]) &&
      length(azuredevops_git_repository.main) == 0 &&
      length(data.external.repository_status) == 0 &&
      length(local_file.main) == 0 &&
      length(local_file.manifest) == 0 &&
      length(terraform_data.prepare) == 0 &&
      length(terraform_data.publish) == 0
    )
    error_message = "With no available projects, report all deferrals without creating repositories, writing clones or running Git operations."
  }
}

run "match_project_names_case_insensitively" {
  command = plan

  override_data {
    target = data.azuredevops_projects.available
    values = {
      projects = [
        { name = "project a", project_id = "11111111-1111-1111-1111-111111111111" },
        { name = "PROJECT B", project_id = "22222222-2222-2222-2222-222222222222" },
      ]
    }
  }

  assert {
    condition = (
      length(output.deferred_projects) == 0 &&
      azuredevops_git_repository.main["Project A/Infrastructure"].project_id == "11111111-1111-1111-1111-111111111111" &&
      azuredevops_git_repository.main["Project B/Infrastructure"].project_id == "22222222-2222-2222-2222-222222222222"
    )
    error_message = "Project-name casing differences must preserve source-based repository addresses and destination project IDs."
  }
}

# A later plan includes the new project as soon as it appears in Azure DevOps.
run "replicate_repository_trees" {
  command = plan

  assert {
    condition     = toset(keys(azuredevops_git_repository.main)) == toset(["Project A/Infrastructure", "Project B/Infrastructure"])
    error_message = "Discover populated repositories while omitting empty and ignored-only repositories."
  }

  assert {
    condition     = local.project_names == toset(["Project A", "Project B"]) && length(output.deferred_projects) == 0
    error_message = "Only populated source projects should be selected, with no deferrals once both projects exist."
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
