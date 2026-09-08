variable "organization_url" {
  type        = string
  description = "Azure DevOps organization URL."

  validation {
    condition     = can(regex("^https://dev\\.azure\\.com/[^/]+/?$", var.organization_url))
    error_message = "organization_url must identify an Azure DevOps organization."
  }
}
