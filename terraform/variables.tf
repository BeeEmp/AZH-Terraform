variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "AZH-Terraform"
}

variable "location" {
  type        = string
  description = "Azure region for the deployment"
  default     = "France Central"
}

variable "unique_suffix" {
  type        = string
  description = "A short unique string to ensure globally unique names for Storage and CosmosDB (e.g., 'abc123')"
  default     = "projazh2026" #  your own random letters/numbers
}