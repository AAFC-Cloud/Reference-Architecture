resource "azurerm_resource_group" "main" {
  name     = "Teamy-Workload-MyFirstWorkload-DEV-RG"
  location = "canadacentral"
  tags = {
    environment = "Development"
    project     = "MyFirstWorkload"
  }
  lifecycle { prevent_destroy = true }
}
