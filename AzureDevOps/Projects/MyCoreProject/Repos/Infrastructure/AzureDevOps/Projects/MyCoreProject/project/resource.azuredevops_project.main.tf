resource "azuredevops_project" "main" {
  name        = "MyCoreProject"
  description = ""

  visibility      = "private"
  version_control = "Git"

  # https://github.com/microsoft/terraform-provider-azuredevops/issues/438
  # can't create the copied template using terraform yet
  # work_item_template = "TODO"

  # features = {
  #   "boards"       = "enabled"
  #   "repositories" = "enabled"
  #   "pipelines"    = "enabled"
  #   "testplans"    = "disabled"
  #   "artifacts"    = "disabled"
  # }
  lifecycle {
    ignore_changes  = [work_item_template]
    prevent_destroy = true
  }
}
