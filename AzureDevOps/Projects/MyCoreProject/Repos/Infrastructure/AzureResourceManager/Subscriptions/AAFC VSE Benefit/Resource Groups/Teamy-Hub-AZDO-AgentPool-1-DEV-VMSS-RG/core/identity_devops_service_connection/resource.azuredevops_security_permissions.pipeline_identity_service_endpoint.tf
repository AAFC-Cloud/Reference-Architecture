# Used by the workload/agent_pool/resource.azuredevops_elastic_pool.main.tf
resource "azuredevops_security_permissions" "pipeline_identity_service_endpoint" {
  namespace_id = data.azuredevops_security_namespace.service_endpoints.id
  token        = "endpoints/${data.azuredevops_project.main.id}/${azuredevops_serviceendpoint_azurerm.main.id}"
  principal    = data.azuredevops_service_principal.pipeline_identity.descriptor

  permissions = {
    Use               = "allow"
    Administer        = "deny"
    Create            = "deny"
    ViewAuthorization = "allow"
    ViewEndpoint      = "allow"
  }

  # Preserve unrelated permissions on this principal and endpoint.
  replace = false
}
