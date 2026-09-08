resource "azuredevops_securityrole_assignment" "main" {
  scope       = "distributedtask.environmentreferencerole"
  resource_id = format("%s_%s", data.azuredevops_project.main.project_id, azuredevops_environment.main.id)
  identity_id = data.azuredevops_storage_key.bootstrap.id
  role_name   = "Administrator"
}
