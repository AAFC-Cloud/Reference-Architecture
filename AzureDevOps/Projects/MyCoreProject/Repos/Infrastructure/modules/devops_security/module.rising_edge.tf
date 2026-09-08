module "rising_edge" {
  source = "../rising_edge"

  storage_account_id  = var.storage_account_id
  blob_container_name = var.blob_container_name
  file_key            = var.file_key
  rising_edge         = lower(data.external.role_assignments.result.change_needed) == "true"
}
