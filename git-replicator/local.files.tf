locals {
  # Keys are <project>/<repository>/<path within repository>.
  files = jsondecode(data.external.source.result.files)
}
