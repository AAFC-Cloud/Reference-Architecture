terraform {
  required_providers {
    azuredevops = { source = "microsoft/azuredevops", version = ">=1.16.0", }
    terraform   = { source = "terraform.io/builtin/terraform", }
  }
}
