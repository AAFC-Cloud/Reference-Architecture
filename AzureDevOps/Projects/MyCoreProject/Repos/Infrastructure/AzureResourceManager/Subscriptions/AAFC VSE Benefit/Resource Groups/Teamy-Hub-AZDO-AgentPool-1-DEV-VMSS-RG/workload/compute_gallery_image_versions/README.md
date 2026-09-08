The pipeline runs after the Ubuntu image VM pipeline succeeds. Terraform then
prepares and generalizes the source VM during the approved apply before creating
the current Azure Compute Gallery image version.

To publish another immutable image version:

1. Update `local.current_image_version.tf`.
2. Add the corresponding `resource.azurerm_shared_image_version.vN.tf` resource.
3. Make that resource depend on `terraform_data.prepare_source_vm`.
