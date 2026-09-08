resource "terraform_data" "prepare_source_vm" {
  input = {
    image_version = local.current_image_version
    source_vm_id  = data.azapi_resource.source_vm.id
  }

  triggers_replace = [
    local.current_image_version,
    data.azapi_resource.source_vm.id,
  ]

  provisioner "local-exec" {
    command     = "& '${path.module}/prepare.ps1'"
    interpreter = ["pwsh", "-NoProfile", "-NonInteractive", "-Command"]
    working_dir = path.module

    environment = {
      AZURE_SUBSCRIPTION_ID         = data.azurerm_subscription.main.subscription_id
      SOURCE_VM_NAME                = data.azapi_resource.source_vm.name
      SOURCE_VM_RESOURCE_GROUP_NAME = data.azurerm_resource_group.main.name
    }
  }
}
