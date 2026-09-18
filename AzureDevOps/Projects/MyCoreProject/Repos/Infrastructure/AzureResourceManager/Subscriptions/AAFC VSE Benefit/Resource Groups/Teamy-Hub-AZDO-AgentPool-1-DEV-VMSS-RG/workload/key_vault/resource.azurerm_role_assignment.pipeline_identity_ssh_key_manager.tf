# Terraform manages the ubuntu-ssh-key secret in the image VM stack.
resource "azurerm_role_assignment" "pipeline_identity_ssh_key_manager" {
  scope                = azurerm_key_vault.main.id
  principal_id         = data.azurerm_user_assigned_identity.agent_pool.principal_id
  role_definition_name = "Key Vault Secrets Officer"
}
