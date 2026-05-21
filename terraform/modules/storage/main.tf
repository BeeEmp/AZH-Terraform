resource "azurerm_storage_account" "frontend" {
  name                     = "azht2026" # Must be globally unique!
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable Static Website Hosting
  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

# Automatically upload your local index.html to the cloud
resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.frontend.name
  storage_container_name = "$web" # The default container for static websites
  type                   = "Block"
  content_type           = "text/html"
  source                 = "../../frontend/index.html" # Path to your local file
}