output "repositories" {
  description = "Repositories created or adopted by the replicator, keyed by project/repository."
  value = {
    for key, repository in azuredevops_git_repository.main : key => {
      id             = repository.id
      project_name   = local.repositories[key].project_name
      name           = repository.name
      default_branch = repository.default_branch
      web_url        = repository.web_url
      remote_url     = repository.remote_url
      file_count     = length([for source_file in local.files : source_file if source_file.repository_key == key])
    }
  }
}
