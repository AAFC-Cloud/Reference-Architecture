resource "azurerm_key_vault_secret" "ssh_key" {
  key_vault_id = data.azurerm_key_vault.main.id
  name         = "vmss-ssh-key"
  value        = tls_private_key.vm_login.private_key_openssh
}
