resource "azurerm_resource_group" "tfmanaged" {
  name = "rg-${var.rg_topic}-${var.rg_increment}"
  location = var.rg_location
}