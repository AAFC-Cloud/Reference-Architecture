resource "terraform_data" "publish" {
  for_each = local.repositories

  triggers_replace = data.external.repository_status[each.key].result.sync_token

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command"]
    command     = "& $env:REPLICATOR_SCRIPT -ManifestPath $env:REPLICATOR_MANIFEST -SyncToken $env:REPLICATOR_SYNC_TOKEN -CommitMessage $env:REPLICATOR_COMMIT_MESSAGE"
    environment = {
      REPLICATOR_SCRIPT         = abspath("${path.module}/scripts/publish-repository.ps1")
      REPLICATOR_MANIFEST       = local_file.manifest[each.key].filename
      REPLICATOR_SYNC_TOKEN     = self.triggers_replace
      REPLICATOR_COMMIT_MESSAGE = coalesce(var.commit_message, "Replicate source snapshot from Reference-Architecture")
    }
  }

  # Includes removals: the full local snapshot must be ready before committing.
  depends_on = [local_file.main, terraform_data.prepare]
}
