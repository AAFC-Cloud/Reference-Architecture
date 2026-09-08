data "external" "repository_status" {
  for_each = local.repository_manifests

  program = ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-File", "${path.module}/scripts/read-repository.ps1"]
  query = {
    manifest_json = jsonencode(each.value)
  }
}
