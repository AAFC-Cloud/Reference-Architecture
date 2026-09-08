variable "file_key" {
  type        = string
  description = "Unique blob name used by the rising-edge marker for this assignment set."

  validation {
    condition     = trimspace(var.file_key) != ""
    error_message = "file_key must not be empty."
  }
}
