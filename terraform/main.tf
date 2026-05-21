resource "azurerm_resource_group" "rg" {
  name     = "azh-terraform-proj"
  location = "France Central"
}

# 1. Frontend Storage
module "frontend_storage" {
  source              = "./modules/storage"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# 2. Backend & Database
module "backend_serverless" {
  source              = "./modules/serverless"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  unique_suffix       = var.unique_suffix # <--- ADD THIS EXACT LINE
}