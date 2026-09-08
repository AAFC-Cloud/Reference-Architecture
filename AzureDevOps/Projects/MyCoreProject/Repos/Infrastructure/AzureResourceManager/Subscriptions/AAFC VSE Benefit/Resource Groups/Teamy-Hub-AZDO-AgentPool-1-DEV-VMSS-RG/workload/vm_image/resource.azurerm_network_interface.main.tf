resource "azurerm_network_interface" "main" {
  name                = "${trimsuffix(data.azurerm_resource_group.main.name, "-RG")}-UbuntuImage-NIC"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = data.azurerm_resource_group.main.tags

  ip_configuration {
    name                          = "${trimsuffix(data.azurerm_resource_group.main.name, "-RG")}-UbuntuImage-NIC"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.main.id
  }
}
