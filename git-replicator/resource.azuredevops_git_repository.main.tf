resource "azuredevops_git_repository" "main" {
  for_each = local.repositories

  project_id     = data.azuredevops_project.main[each.value.project_name].id
  name           = each.value.repository_name
  default_branch = "refs/heads/main"

  # Preserve the existing initialization behavior and resource addresses.
  initialization {
    init_type = "Clean"
  }

  lifecycle {
    # An imported repository must keep its existing history.
    ignore_changes = [initialization]
  }
}
