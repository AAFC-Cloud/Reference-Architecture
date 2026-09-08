resource "azurerm_linux_virtual_machine_scale_set" "main" {
  name                = "Teamy-Hub-AZDO-AgentPool-1-DEV-VMSS"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = data.azurerm_resource_group.main.tags

  sku       = "Standard_D2s_v3"
  instances = 1

  overprovision          = false
  single_placement_group = false

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    public_key = tls_private_key.vm_login.public_key_openssh
    username   = "azureuser"
  }

  upgrade_mode = "Manual"

  #   custom_data     = base64encode(data.local_file.main.content)
  source_image_id = data.azurerm_shared_image_version.main.id
  dynamic "plan" {
    for_each = data.azurerm_shared_image.main.purchase_plan

    content {
      name      = plan.value.name
      product   = plan.value.product
      publisher = plan.value.publisher
    }
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadOnly"

    diff_disk_settings {
      option = "Local"
    }
  }

  network_interface {
    name    = "${data.azurerm_resource_group.main.name}-VMSS-NIC"
    primary = true

    ip_configuration {
      name      = "${data.azurerm_resource_group.main.name}-VMSS-IPConfig"
      primary   = true
      subnet_id = data.azurerm_subnet.main.id
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  # depends_on = [
  #   time_sleep.cis_images_policy_exemption
  # ]

  lifecycle {
    # Don't clobber tags.__AzureDevOpsElasticPool, tags.__AzureDevOpsElasticPoolTimeStamp
    # Don't change instance count, let Azure DevOps manage it
    ignore_changes = [tags, instances]
  }
}
