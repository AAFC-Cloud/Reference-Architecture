resource "azuredevops_git_repository" "main" {
  for_each = local.repositories

  project_id     = local.available_project_ids[lower(each.value.project_name)]
  name           = each.value.repository_name
  default_branch = "refs/heads/main"

  # Preserve the existing initialization behavior and resource addresses.
  initialization {
    init_type = "Clean"
  }

  lifecycle {
    # A narrower selection or missing project must not delete managed repositories.
    prevent_destroy = true
    # An imported repository must keep its existing history.
    ignore_changes = [initialization]
  }
}
