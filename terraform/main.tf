locals {
  name_prefix        = "${var.project_name}-${var.environment}"
  name_prefix_nodash = "${var.project_name}${var.environment}"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_prefix}"
  location = var.location
}

module "identity" {
  source       = "./modules/identity"
  project_name = var.project_name
  environment  = var.environment
  team_members = var.team_members
}

module "frontend_storage" {
  source               = "./modules/storage"
  storage_account_name = "st${local.name_prefix_nodash}${var.unique_suffix}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  admin_group_id       = module.identity.admin_group_id
  dev_group_id         = module.identity.dev_group_id
}

# (Your serverless module block will go here once you write it)