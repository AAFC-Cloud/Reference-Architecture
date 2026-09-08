If you see

```
╷
│ Error: No valid credentials found.
│
│   with provider["registry.terraform.io/microsoft/azuredevops"],
│   on provider.azuredevops.tf line 1, in provider "azuredevops":
│    1: provider "azuredevops" {
│
╵
```

then you should run the following code before `terraform apply`:

```pwsh
$env:AZDO_PERSONAL_ACCESS_TOKEN=Read-Host -MaskInput "Enter PAT"
```

you will paste your PAT when it prompts you.

Note that `-MaskInput` is a pwsh feature, if you don't have PowerShell Core it may complain.