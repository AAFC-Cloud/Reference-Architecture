resource "azurerm_linux_virtual_machine" "main" {
  name                = "${trimsuffix(data.azurerm_resource_group.main.name, "-RG")}-UbuntuImage-VM"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = data.azurerm_resource_group.main.tags

  custom_data           = data.template_cloudinit_config.main.rendered
  network_interface_ids = [azurerm_network_interface.main.id]
  size                  = "Standard_D2s_v3"


  source_image_reference {
    offer     = local.marketplace_image.offer
    publisher = local.marketplace_image.publisher
    sku       = local.marketplace_image.sku
    version   = local.marketplace_image.version
  }
  # Only images with a purchase plan require Marketplace agreement validation.
  dynamic "plan" {
    for_each = data.azurerm_marketplace_agreement.main

    content {
      name      = plan.value.plan
      product   = plan.value.offer
      publisher = plan.value.publisher
    }
  }

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    public_key = tls_private_key.vm_login.public_key_openssh
    username   = "azureuser"
  }


  allow_extension_operations                             = true
  bypass_platform_safety_checks_on_user_schedule_enabled = false
  encryption_at_host_enabled                             = false
  extensions_time_budget                                 = "PT1H30M"
  # patch_assessment_mode                                  = "ImageDefault"
  # patch_mode                                             = "AutomaticByPlatform"
  priority           = "Regular"
  provision_vm_agent = true
  # reboot_setting                                         = "IfRequired"
  secure_boot_enabled = false

  os_disk {
    storage_account_type      = "Premium_LRS"
    caching                   = "ReadWrite"
    write_accelerator_enabled = false
    disk_size_gb              = 30
  }
  identity {
    type = "SystemAssigned"
  }
}
