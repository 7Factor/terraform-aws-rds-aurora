output "engine" {
  value = "mysql"
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
  value = mysql_user.credential.user
}

output "password" {
  value     = random_password.credential.result
  sensitive = true
}
