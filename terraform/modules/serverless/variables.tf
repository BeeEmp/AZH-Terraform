variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "The Azure region."
}

variable "unique_suffix" {
  type        = string
  description = "Suffix to guarantee unique names for global resources. Change this if the deployment fails!"
}