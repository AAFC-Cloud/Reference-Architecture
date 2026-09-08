data "azapi_resource" "source_vm" {
  type                   = "Microsoft.Compute/virtualMachines@2024-03-01"
  parent_id              = data.azurerm_resource_group.main.id
  name                   = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS-UbuntuImage-VM"
  response_export_values = ["plan"]
}
