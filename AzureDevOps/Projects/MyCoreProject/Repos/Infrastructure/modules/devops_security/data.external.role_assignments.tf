data "external" "role_assignments" {
  program = [
    "pwsh",
    "-NoProfile",
    "-File",
    "${path.module}/scripts/read.ps1",
  ]

  query = {
    organization_url = local.organization_url
    identity_id      = var.identity_id
    assignments_json = jsonencode(var.role_assignments)
    api_version      = var.api_version
  }
}
