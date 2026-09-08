variable "blob_container_name" {
  type        = string
  description = "Name of the existing blob container in which the marker is stored."

  validation {
    condition     = trimspace(var.blob_container_name) != ""
    error_message = "blob_container_name must not be empty."
  }
}
