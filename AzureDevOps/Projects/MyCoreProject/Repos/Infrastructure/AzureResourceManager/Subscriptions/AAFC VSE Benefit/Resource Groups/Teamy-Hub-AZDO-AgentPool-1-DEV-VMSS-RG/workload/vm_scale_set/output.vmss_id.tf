output "vmss_id" {
  description = "Resource ID of the virtual machine scale set."
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}
