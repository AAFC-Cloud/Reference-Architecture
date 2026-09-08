resource "terraform_data" "edge_claim" {
  input = {
    storage_account_name = local.storage_account_name
    blob_container_name  = var.blob_container_name
    file_key             = var.file_key
    generation           = data.external.rising_edge.result.generation
  }

  triggers_replace = [
    var.storage_account_id,
    var.blob_container_name,
    var.file_key,
    data.external.rising_edge.result.generation,
  ]

  depends_on = [terraform_data.marker_lifecycle]

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    command     = "& '${path.module}/scripts/claim.ps1'"

    environment = {
      RISING_EDGE_STORAGE_ACCOUNT_NAME = self.input.storage_account_name
      RISING_EDGE_BLOB_CONTAINER_NAME  = self.input.blob_container_name
      RISING_EDGE_FILE_KEY             = self.input.file_key
      RISING_EDGE_GENERATION           = self.input.generation
      RISING_EDGE_MARKER_EXISTS        = data.external.rising_edge.result.marker_exists
      RISING_EDGE_MARKER_ETAG          = data.external.rising_edge.result.marker_etag
    }
  }
}
