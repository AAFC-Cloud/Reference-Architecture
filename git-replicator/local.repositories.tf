locals {
  # Keys include the project because repository names can repeat across projects.
  selected_repositories = {
    for key, repository in jsondecode(data.external.source.result.repositories) :
    key => repository
    if var.project_names == null ? true : contains(var.project_names, repository.project_name)
  }

  repositories = {
    for key, repository in local.selected_repositories :
    key => repository
    if contains(keys(local.available_project_ids), lower(repository.project_name))
  }
}
