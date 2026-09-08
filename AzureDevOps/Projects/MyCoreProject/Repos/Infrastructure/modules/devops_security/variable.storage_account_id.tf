variable "storage_account_id" {
  type        = string
  description = "Resource ID of the storage account containing the rising-edge marker."

  validation {
    condition = can(regex(
      "(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[^/]+$",
      var.storage_account_id,
    ))
    error_message = "storage_account_id must be an Azure Storage account resource ID."
  }
}
