resource "azurerm_role_assignment" "agent_pool_vmss_ssh_key_reader" {
  scope                = "${azurerm_key_vault.main.id}/secrets/vmss-ssh-key"
  principal_id         = data.azurerm_user_assigned_identity.agent_pool.principal_id
  role_definition_name = "Key Vault Secrets User"
}
