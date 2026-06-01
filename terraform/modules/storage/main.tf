resource "azurerm_storage_account" "frontend" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_static_website" "website" {
  storage_account_id = azurerm_storage_account.frontend.id
  index_document     = "index.html"
  error_404_document = "404.html"
}

resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.frontend.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source                 = "${path.root}/../frontend/index.html"
  depends_on             = [azurerm_storage_account_static_website.website]
}

resource "azurerm_storage_container" "data_container" {
  name                  = "project-data"
  storage_account_id    = azurerm_storage_account.frontend.id
  container_access_type = "private"
}

resource "azurerm_storage_share" "file_share" {
  name                 = "project-shares"
  storage_account_id   = azurerm_storage_account.frontend.id
  quota                = 50
}

resource "azurerm_role_assignment" "admin_blob_owner" {
  scope                = azurerm_storage_account.frontend.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.admin_group_id
}

resource "azurerm_role_definition" "dev_no_delete" {
  name        = "Storage Data Writer (No Delete) - ${var.storage_account_name}"
  scope       = azurerm_storage_account.frontend.id
  description = "Allows developers to read and write data, but prohibits deletion."

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action"
    ]
    not_data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete"
    ]
  }
  assignable_scopes = [azurerm_storage_account.frontend.id]
}

resource "azurerm_role_assignment" "dev_custom_assignment" {
  scope              = azurerm_storage_account.frontend.id
  role_definition_id = azurerm_role_definition.dev_no_delete.role_definition_resource_id
  principal_id       = var.dev_group_id
}