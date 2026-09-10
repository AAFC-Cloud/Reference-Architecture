resource "azuredevops_build_definition" "main" {
  for_each     = local.pipelines
  project_id   = data.azuredevops_project.main.id
  path         = local.pipeline_paths[each.key]
  name         = each.value.name
  queue_status = try(each.value.enabled, true) ? "enabled" : "disabled"
  repository {
    repo_id     = data.azuredevops_git_repository.client_workloads.id
    repo_type   = "TfsGit"
    branch_name = "refs/heads/main"
    yml_path    = local.pipeline_yaml_paths[each.key]
  }

  ci_trigger {
    use_yaml = true
  }

  lifecycle {
    precondition {
      condition = length(local.duplicate_pipeline_yaml_paths) == 0
      error_message = format(
        "Each .tfvars.pipeline_registration file must point to a unique yaml_path. Duplicate yaml_path values and registration files: %s",
        jsonencode(local.duplicate_pipeline_yaml_paths)
      )
    }

    precondition {
      condition = length(local.pipeline_yaml_validation_errors) == 0
      error_message = format(
        "Pipeline YAML metadata validation failed. Each registered YAML must trigger its own directory; when pathInRepo is present, it must match that directory: %s",
        jsonencode(local.pipeline_yaml_validation_errors)
      )
    }
  }
}
