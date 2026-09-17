output "deferred_projects" {
  description = "Selected source projects not yet ready or not visible in Azure DevOps. Run the replicator again after provisioning or restoring access."
  value       = sort(tolist(local.deferred_projects))
}
