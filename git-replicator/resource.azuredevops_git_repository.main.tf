resource "azuredevops_git_repository" "main" {
  for_each = local.repositories

  project_id     = data.azuredevops_project.main[each.value.project_name].id
  name           = each.value.repository_name
  default_branch = "refs/heads/main"

  # The file resource needs a branch that already has an initial commit.
  initialization {
    init_type = "Clean"
  }

  lifecycle {
    # An imported repository must keep its existing history.
    ignore_changes = [initialization]
  }
}
