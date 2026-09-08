resource "azurerm_virtual_machine_scale_set_extension" "main" {
  name                         = "Microsoft.Azure.DevOps.Pipelines.Agent"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.main.id
  publisher                    = "Microsoft.VisualStudio.Services"
  type                         = "TeamServicesAgentLinux"
  type_handler_version         = "1.26"
  automatic_upgrade_enabled    = false
  auto_upgrade_minor_version   = false
  settings = jsonencode({
    "isPipelinesAgent" : true,
    "agentFolder" : "/agent",
    # https://github.com/microsoft/azure-pipelines-agent/releases/latest
    "agentDownloadUrl" : "https://download.agent.dev.azure.com/agent/5.277.0/vsts-agent-linux-x64-5.277.0.tar.gz",
    # https://github.com/MicrosoftDocs/azure-devops-docs/blob/main/docs/pipelines/agents/scale-set-agents.md#lifecycle-of-a-scale-set-agent
    "enableScriptDownloadUrl" : "https://vstsagenttools.blob.core.windows.net/tools/ElasticPools/Linux/18/enableagent.sh"
  })
}
