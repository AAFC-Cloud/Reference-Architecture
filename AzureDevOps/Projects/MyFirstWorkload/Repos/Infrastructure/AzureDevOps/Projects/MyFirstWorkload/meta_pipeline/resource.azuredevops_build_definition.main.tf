resource "azuredevops_build_definition" "main" {
  for_each                = local.pipelines
  project_id              = data.azuredevops_project.main.id
  path                    = local.pipeline_paths[each.key]
  name                    = each.value.name
  queue_status            = try(each.value.enabled, true) ? "enabled" : "disabled"
  job_authorization_scope = "project"
  repository {
    repo_id     = data.azuredevops_git_repository.client_workloads.id
    repo_type   = "TfsGit"
    branch_name = "refs/heads/main"
    yml_path    = local.pipeline_yaml_paths[each.key]
  }

  ci_trigger {
    use_yaml = true
  }

  features {
    skip_first_run = true
  }

  depends_on = [terraform_data.pipeline_validation]
}
