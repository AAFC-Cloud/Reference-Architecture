variable "role_assignments" {
  type = map(object({
    scope       = string
    resource_id = string
    role_name   = string
  }))
  description = "Named Azure DevOps security-role assignments reconciled as one lifecycle unit."

  validation {
    condition = length(var.role_assignments) > 0 && alltrue([
      for assignment in values(var.role_assignments) :
      trimspace(assignment.scope) != "" &&
      trimspace(assignment.resource_id) != "" &&
      trimspace(assignment.role_name) != ""
    ])
    error_message = "role_assignments must contain at least one assignment with non-empty scope, resource_id, and role_name values."
  }
}
