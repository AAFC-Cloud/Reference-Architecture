locals {
  # Keys are <project>/<repository>/<path within repository>.
  files = {
    for key, source_file in jsondecode(data.external.source.result.files) :
    key => source_file
    if contains(keys(local.repositories), source_file.repository_key)
  }
}
