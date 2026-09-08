locals {
  clone_root = abspath("${path.module}/.terraform/repos")

  # Include the implementation digest so script updates are applied once too.
  sync_implementation = sha256(join("", [
    for script in ["git-common.ps1", "read-repository.ps1", "prepare-repository.ps1", "publish-repository.ps1"] :
    filesha256("${path.module}/scripts/${script}")
  ]))

  repository_manifests = {
    for key, repository in azuredevops_git_repository.main : key => {
      repository_key = key
      clone_path     = "${local.clone_root}/${key}"
      remote_url     = repository.remote_url
      branch         = "refs/heads/main"
      implementation = local.sync_implementation
      files = {
        for source_file in local.files : source_file.repository_path => {
          sha256 = filesha256("${local.source_root}/${source_file.source_path}")
          mode   = source_file.git_mode
        } if source_file.repository_key == key
      }
    }
  }
}
