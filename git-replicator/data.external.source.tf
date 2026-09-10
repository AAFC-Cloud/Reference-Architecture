data "external" "source" {
  program = ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-File", "${path.module}/discover-repositories.ps1"]

  query = {
    source_root = local.source_root
  }
}
