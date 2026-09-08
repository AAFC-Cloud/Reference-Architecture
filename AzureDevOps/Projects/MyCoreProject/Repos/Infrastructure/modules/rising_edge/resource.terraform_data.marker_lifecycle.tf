resource "terraform_data" "marker_lifecycle" {
  input = {
    storage_account_name = local.storage_account_name
    blob_container_name  = var.blob_container_name
    file_key             = var.file_key
  }

  triggers_replace = [
    var.storage_account_id,
    var.blob_container_name,
    var.file_key,
  ]

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${path.module}/scripts/delete.ps1'"

    environment = {
      RISING_EDGE_STORAGE_ACCOUNT_NAME = self.input.storage_account_name
      RISING_EDGE_BLOB_CONTAINER_NAME  = self.input.blob_container_name
      RISING_EDGE_FILE_KEY             = self.input.file_key
    }
  }
}
