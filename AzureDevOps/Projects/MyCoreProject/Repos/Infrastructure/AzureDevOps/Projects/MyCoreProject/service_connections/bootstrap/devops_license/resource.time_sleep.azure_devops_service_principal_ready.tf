# resource "time_sleep" "azure_devops_service_principal_ready" {
#   # Finish this root only after the DevOps entitlement has had time to propagate.
#   create_duration = "300s"

#   triggers = {
#     entitlement_id = azuredevops_service_principal_entitlement.main.id
#   }
# }
