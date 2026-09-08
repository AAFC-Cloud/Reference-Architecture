locals {
  project_names = toset([for repository in local.repositories : repository.project_name])
}
