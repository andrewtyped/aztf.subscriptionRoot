output "resource_group" {
    value = {
        name = azurerm_resource_group.tfmanaged.name
        location = azurerm_resource_group.tfmanaged.location
    }
}