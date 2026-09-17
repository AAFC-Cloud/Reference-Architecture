data "external" "source" {
  program = ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-File", "${path.module}/discover-repositories.ps1"]

  query = {
    source_root = local.source_root
  }

  lifecycle {
    postcondition {
      condition = var.project_names == null ? true : length(setsubtract(
        var.project_names,
        toset([for repository in jsondecode(self.result.repositories) : repository.project_name])
      )) == 0
      error_message = "Each selected project must contain a discovered repository with eligible source files. Check project_names for misspelled or empty projects."
    }
  }
}
