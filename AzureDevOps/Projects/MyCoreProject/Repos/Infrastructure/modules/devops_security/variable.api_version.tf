variable "api_version" {
  type        = string
  description = "Azure DevOps security-role API version."
  default     = "7.1-preview.1"

  validation {
    condition     = trimspace(var.api_version) != ""
    error_message = "api_version must not be empty."
  }
}
