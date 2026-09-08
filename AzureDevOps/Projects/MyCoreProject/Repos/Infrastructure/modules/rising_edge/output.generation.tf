output "generation" {
  description = "Persistent generation token. Use this value in triggers_replace for the operation that reconciles the rising edge."
  value       = terraform_data.edge_claim.input.generation
}
