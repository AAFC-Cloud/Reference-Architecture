output "application_object_id" {
  description = "Terraform application resource ID used to attach federated credentials."
  value       = azuread_application_registration.main.id
}
