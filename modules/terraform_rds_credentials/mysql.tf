resource "mysql_user" "credential" {
  count = var.database_type == "mysql" ? 1 : 0

  user               = var.name
  host               = "%"
  plaintext_password = random_password.credential.result

  lifecycle {
    precondition {
      condition     = length(var.name) <= 32
      error_message = "MySQL usernames can be at most 32 characters. \"${var.name}\" is ${length(var.name)}."
    }
  }
}

# Grants on database.* also cover tables created later
resource "mysql_grant" "credential" {
  count = var.database_type == "mysql" ? 1 : 0

  user       = mysql_user.credential[0].user
  host       = mysql_user.credential[0].host
  database   = data.aws_rds_cluster.database.database_name
  privileges = var.privileges
}
