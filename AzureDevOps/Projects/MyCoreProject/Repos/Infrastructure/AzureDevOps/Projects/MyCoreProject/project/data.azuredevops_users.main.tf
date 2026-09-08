data "azuredevops_users" "main" {
  for_each      = { for person in local.people : "${person.origin}:${person.origin_id}" => person }
  origin        = each.value.origin
  origin_id     = each.value.origin_id
  subject_types = [each.value.origin]
  lifecycle {
    postcondition {
      condition     = length(self.users) > 0
      error_message = "User ${each.key} not found in Azure DevOps."
    }
  }
}
