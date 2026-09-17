locals {
  # Match the provider's case-insensitive project-name lookup while preserving
  # source-based repository keys and existing resource addresses.
  available_project_ids = {
    for project in flatten([for result in data.azuredevops_projects.available : result.projects]) :
    lower(project.name) => project.project_id
  }
}
