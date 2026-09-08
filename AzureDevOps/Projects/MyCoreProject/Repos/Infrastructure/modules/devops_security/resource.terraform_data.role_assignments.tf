resource "terraform_data" "role_assignments" {
  input = {
    organization_url = local.organization_url
    identity_id      = var.identity_id
    assignments_json = jsonencode(var.role_assignments)
    api_version      = var.api_version
  }

  triggers_replace = [
    module.rising_edge.generation,
    local.organization_url,
    var.identity_id,
    sha256(jsonencode(var.role_assignments)),
    var.api_version,
  ]

  depends_on = [module.rising_edge]

  provisioner "local-exec" {
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    on_failure  = fail
    command     = "& '${path.module}/scripts/set.ps1'"

    environment = {
      DEVOPS_SECURITY_ORGANIZATION_URL = self.input.organization_url
      DEVOPS_SECURITY_IDENTITY_ID      = self.input.identity_id
      DEVOPS_SECURITY_ASSIGNMENTS_JSON = self.input.assignments_json
      DEVOPS_SECURITY_API_VERSION      = self.input.api_version
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-NoProfile", "-Command"]
    on_failure  = continue
    command     = "& '${path.module}/scripts/delete.ps1'"

    environment = {
      DEVOPS_SECURITY_ORGANIZATION_URL = self.input.organization_url
      DEVOPS_SECURITY_IDENTITY_ID      = self.input.identity_id
      DEVOPS_SECURITY_ASSIGNMENTS_JSON = self.input.assignments_json
      DEVOPS_SECURITY_API_VERSION      = self.input.api_version
    }
  }
}
