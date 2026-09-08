# resource "time_sleep" "entra_service_principal_ready" {
#   # Allow the Entra service principal to propagate before enrolling it in DevOps.
#   create_duration = "300s"

#   triggers = {
#     service_principal_object_id = data.terraform_remote_state.bootstrap.outputs.service_principal_object_id
#   }
# }
