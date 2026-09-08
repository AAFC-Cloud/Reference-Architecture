variable "identity_id" {
  type        = string
  description = "Azure DevOps internal identity ID (storage key), not the Entra object ID."

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.identity_id))
    error_message = "identity_id must be an Azure DevOps storage-key GUID."
  }
}
