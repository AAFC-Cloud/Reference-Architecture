variable "file_key" {
  type        = string
  description = "Blob name used as the persistent marker key. It must be unique to this rising-edge instance."

  validation {
    condition     = trimspace(var.file_key) != ""
    error_message = "file_key must not be empty."
  }
}
