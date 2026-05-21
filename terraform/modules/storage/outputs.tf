output "website_url" {
  description = "The URL of the static website."
  value       = azurerm_storage_account.frontend.primary_web_endpoint
}