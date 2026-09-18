variable "commit_message" {
  description = "Optional commit message for each changed repository snapshot."
  type        = string
  # default     = null
  nullable    = true

  validation {
    condition     = var.commit_message == null || trimspace(var.commit_message) != ""
    error_message = "commit_message must be null or contain at least one non-whitespace character."
  }
}
