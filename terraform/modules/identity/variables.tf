variable "project_name" { type = string }
variable "environment" { type = string }
variable "team_members" {
  type = map(object({
    role       = string
    first_name = string
    last_name  = string
  }))
}