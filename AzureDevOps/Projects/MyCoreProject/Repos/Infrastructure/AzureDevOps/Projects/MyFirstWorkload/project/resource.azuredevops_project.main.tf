resource "azuredevops_project" "main" {
  name            = "MyFirstWorkload"
  description     = "First independently deployed workload: Azure App Configuration."
  visibility      = "private"
  version_control = "Git"
  lifecycle {
    ignore_changes  = [work_item_template]
    prevent_destroy = true
  }
}
