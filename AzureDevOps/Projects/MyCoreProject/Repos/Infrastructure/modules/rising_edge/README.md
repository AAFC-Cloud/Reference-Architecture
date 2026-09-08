# Rising edge

This module converts a level signal into a persistent generation token. It stores the generation in an existing Azure Blob Storage container using the Azure CLI's current Microsoft Entra login.

When `rising_edge` is false, the output generation remains unchanged. When it is true, the module claims a new generation during apply. A consumer can use the output in `triggers_replace` to run an idempotent reconciliation operation.

```hcl
module "example_rising_edge" {
  source = "../../modules/rising_edge"

  storage_account_id  = "/subscriptions/.../providers/Microsoft.Storage/storageAccounts/example"
  blob_container_name = "tfstate"
  file_key             = "_terraform_control/rising_edges/example.json"
  rising_edge          = local.change_needed
}

resource "terraform_data" "example_reconciliation" {
  triggers_replace = [module.example_rising_edge.generation]

  depends_on = [module.example_rising_edge]

  provisioner "local-exec" {
    # Perform an idempotent operation that makes local.change_needed false.
  }
}
```

The marker key must be unique to the module instance. The caller requires blob read, write, and delete permissions. `az storage blob` is always invoked with `--auth-mode login`; storage account keys are not used.

Generation changes replace the reconciliation resource. A destroy provisioner
on that resource will therefore run before every reconciliation as well as when
the configuration is removed. Use that model when delete-and-recreate behavior
is acceptable; otherwise put remote-object deprovisioning in a separate stable
lifecycle resource.
