locals {
  project_names = toset([for repository in local.selected_repositories : repository.project_name])
}
