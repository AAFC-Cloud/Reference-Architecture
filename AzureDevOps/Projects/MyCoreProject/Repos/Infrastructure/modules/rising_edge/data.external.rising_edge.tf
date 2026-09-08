data "external" "rising_edge" {
  program = [
    "pwsh",
    "-NoProfile",
    "-File",
    "${path.module}/scripts/read.ps1",
  ]

  query = {
    storage_account_name = local.storage_account_name
    blob_container_name  = var.blob_container_name
    file_key             = var.file_key
    rising_edge          = tostring(var.rising_edge)
  }
}
