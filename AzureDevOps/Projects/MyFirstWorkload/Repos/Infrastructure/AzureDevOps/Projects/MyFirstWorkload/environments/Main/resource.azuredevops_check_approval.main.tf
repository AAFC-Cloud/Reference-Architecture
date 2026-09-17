resource "azuredevops_check_approval" "main" {
  project_id           = data.azuredevops_project.main.id
  target_resource_id   = azuredevops_environment.main.id
  target_resource_type = "environment"
  approvers = [
    for approver in data.azuredevops_users.main : one(approver.users).id
  ]
  instructions               = "Review the saved Terraform plan for MyFirstWorkload."
  minimum_required_approvers = 1
  requester_can_approve      = true
}
