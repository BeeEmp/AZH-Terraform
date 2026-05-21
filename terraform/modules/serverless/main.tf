# 1. Monitoring (Log Analytics & Application Insights)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "logazurwork1-${var.unique_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

resource "azurerm_application_insights" "appinsights" {
  name                = "appi-app-${var.unique_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

# 2. Database (Cosmos DB)
# Note: Cosmos DB names must be globally unique!
resource "azurerm_cosmosdb_account" "db" {
  name                = "cosmoterra-${var.unique_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "sqldb" {
  name                = "BackendDB"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
  throughput          = 400
}

# 3. Compute (Azure Function App & required Storage)
# Note: Storage account names must be globally unique and lowercase!
resource "azurerm_storage_account" "fnstorage" {
  name                     = "stfun${var.unique_suffix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-${var.unique_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1" # Dynamic consumption plan (cheapest/serverless tier)
}

resource "azurerm_linux_function_app" "function" {
  name                       = "linuxAZFH-${var.unique_suffix}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  storage_account_name       = azurerm_storage_account.fnstorage.name
  storage_account_access_key = azurerm_storage_account.fnstorage.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  #!!possible change

  site_config {
    application_stack {
      python_version = "3.9" # Change to Node or C# if your backend is not Python
    }
  }

  # Turn on System Assigned Managed Identity for IAM
  identity {
    type = "SystemAssigned"
  }
}

# 4. Security (IAM Role Assignment)
# Grants the Function App permission to read/write to Cosmos DB without passwords
resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_role" {
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.db.name
  principal_id        = azurerm_linux_function_app.function.identity[0].principal_id
  scope               = azurerm_cosmosdb_account.db.id
  
  # This string of zeros is Microsoft's official ID for the "Built-in Data Contributor" role
  role_definition_id  = "${azurerm_cosmosdb_account.db.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
}