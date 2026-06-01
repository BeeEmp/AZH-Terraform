output "frontend_website_url" {
  description = "The public URL for your frontend application."
  value       = module.frontend_storage.website_url
}

output "user_emails" {
  description = "List of generated user emails."
  value       = module.identity.created_user_emails
}