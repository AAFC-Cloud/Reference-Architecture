locals {
  deferred_projects = toset([
    for name in local.project_names : name
    if !contains(keys(local.available_project_ids), lower(name))
  ])
}
