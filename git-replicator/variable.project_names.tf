variable "project_names" {
  description = "Optional source-project selection. Null selects all discovered projects; unavailable Azure DevOps projects are deferred automatically. Include every project already managed in this state."
  type        = set(string)
  default     = null

  validation {
    condition     = var.project_names == null ? true : length(var.project_names) > 0
    error_message = "Select at least one project, or use null to publish every discovered project."
  }
}
