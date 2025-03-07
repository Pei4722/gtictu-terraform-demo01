# Import azure resource group
resource "azurerm_resource_group" "rg-import" {
  name     = "rg-pei-import-tf001"
  location = "East Asia"

  tags = {
    Tool = "Terraform"
  }
}