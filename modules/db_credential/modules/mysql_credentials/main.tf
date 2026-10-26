terraform {
  required_version = ">= 1.3.0"

  required_providers {
    mysql = {
      source  = "petoju/mysql"
      version = ">= 3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3"
    }
  }
}

resource "random_password" "credential" {
  length  = var.password_length
  special = false
}

resource "mysql_user" "credential" {
  user               = var.username
  host               = var.user_host
  plaintext_password = random_password.credential.result
}

resource "mysql_grant" "credential" {
  user       = mysql_user.credential.user
  host       = mysql_user.credential.host
  database   = var.database
  privileges = var.privileges
}
