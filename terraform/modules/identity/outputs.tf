output "admin_group_id" { value = azuread_group.admins.object_id }
output "dev_group_id"   { value = azuread_group.devs.object_id }
output "created_user_emails" {
  value = { for k, u in azuread_user.team : k => u.user_principal_name }
}