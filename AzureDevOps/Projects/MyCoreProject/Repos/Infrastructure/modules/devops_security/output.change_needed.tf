output "change_needed" {
  description = "Whether the read performed for the current graph detected assignment drift."
  value       = lower(data.external.role_assignments.result.change_needed) == "true"
}
