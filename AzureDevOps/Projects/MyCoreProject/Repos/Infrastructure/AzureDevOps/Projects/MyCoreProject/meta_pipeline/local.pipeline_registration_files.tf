locals {
  pipeline_registration_files = fileset(
    local.repository_root,
    "**/*.tfvars.pipeline_registration"
  )
}
