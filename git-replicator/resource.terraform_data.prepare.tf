resource "terraform_data" "prepare" {
  for_each = local.repositories

  triggers_replace = data.external.repository_status[each.key].result.sync_token

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command"]
    command     = "& $env:REPLICATOR_SCRIPT -ManifestPath $env:REPLICATOR_MANIFEST"
    environment = {
      REPLICATOR_SCRIPT   = abspath("${path.module}/scripts/prepare-repository.ps1")
      REPLICATOR_MANIFEST = local_file.manifest[each.key].filename
    }
  }
}
