output "engine" {
  value = "postgres"
}

output "host" {
  value = var.db_host
}

output "port" {
  value = var.db_port
}

output "dbname" {
  value = var.database
}

output "username" {
  value = postgresql_role.credential.name
}

output "password" {
  value     = random_password.credential.result
  sensitive = true
}
