terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

data "azuread_domains" "default" {
  only_default = true
}

resource "azuread_group" "admins" {
  display_name     = "ag-${var.project_name}-${var.environment}-admins"
  security_enabled = true
}

resource "azuread_group" "devs" {
  display_name     = "ag-${var.project_name}-${var.environment}-devs"
  security_enabled = true
}

resource "azuread_user" "team" {
  for_each = var.team_members

  user_principal_name   = "${each.key}@${data.azuread_domains.default.domains.0.domain_name}"
  display_name          = "${each.value.first_name} ${each.value.last_name}"
  mail_nickname         = each.key
  password              = "Start@${title(var.project_name)}2026!"
  force_password_change = true 
}

resource "azuread_group_member" "admin_assignments" {
  for_each = { for k, v in var.team_members : k => v if v.role == "admin" }
  
  group_object_id  = azuread_group.admins.object_id
  member_object_id = azuread_user.team[each.key].object_id
}

resource "azuread_group_member" "dev_assignments" {
  for_each = { for k, v in var.team_members : k => v if v.role == "dev" }
  
  group_object_id  = azuread_group.devs.object_id
  member_object_id = azuread_user.team[each.key].object_id
}