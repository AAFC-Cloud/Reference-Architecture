# Hand file ownership to Git without sending any file-deletion requests.
# Keep this block until every workspace using the old resources has migrated.
removed {
  from = azuredevops_git_repository_file.main

  lifecycle {
    destroy = false
  }
}
