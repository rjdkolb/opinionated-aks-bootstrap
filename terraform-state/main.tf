provider "azurerm" {
  version = "2.13.0"
  features {}
}

resource "azurerm_resource_group" "terraform-state-rg" {
  name = "terraform-state-rg"
  location = var.location
}

resource "azurerm_storage_account" "terraformstorage" {
  name = var.terraform_storage_name
  resource_group_name = azurerm_resource_group.terraform-state-rg.name
  account_kind = "BlobStorage"
  location = var.location
  account_tier = "Standard"
  account_replication_type = "GRS"
}
resource "azurerm_storage_container" "terraformstorage-container" {
  name                  = "terraform-state"
  storage_account_name  = azurerm_storage_account.terraformstorage.name
  container_access_type = "private"
}