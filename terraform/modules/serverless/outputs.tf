output "function_app_name" {
  description = "The name of the deployed Function App."
  value       = azurerm_linux_function_app.function.name
}

output "cosmos_db_endpoint" {
  description = "The endpoint URL for Cosmos DB."
  value       = azurerm_cosmosdb_account.db.endpoint
}