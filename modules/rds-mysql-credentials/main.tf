terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3"
    }
    mysql = {
      source  = "petoju/mysql"
      version = ">= 3"
    }
  }
}

# Look up the cluster for its endpoint, port and database name
data "aws_rds_cluster" "database" {
  cluster_identifier = var.database_identifier

  lifecycle {
    postcondition {
      condition     = contains(["aurora", "aurora-mysql", "mysql"], self.engine)
      error_message = "The cluster's engine is ${self.engine}, not MySQL. Use rds-postgres-credentials for PostgreSQL clusters."
    }
  }
}

resource "random_password" "credential" {
  length  = 32
  special = false
}

resource "mysql_user" "credential" {
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
  user       = mysql_user.credential.user
  host       = mysql_user.credential.host
  database   = data.aws_rds_cluster.database.database_name
  privileges = var.privileges
}

resource "aws_secretsmanager_secret" "credential" {
  name                    = var.name
  recovery_window_in_days = var.recovery_window_in_days
}

# Uses the same JSON keys as RDS-managed secrets, so anything that already knows how to read those (rotation lambdas,
# drivers, etc.) can read these too
resource "aws_secretsmanager_secret_version" "credential" {
  secret_id = aws_secretsmanager_secret.credential.id
  secret_string = jsonencode({
    engine   = "mysql"
    host     = data.aws_rds_cluster.database.endpoint
    port     = data.aws_rds_cluster.database.port
    dbname   = data.aws_rds_cluster.database.database_name
    username = mysql_user.credential.user
    password = random_password.credential.result
  })
}

data "aws_iam_policy_document" "read_credential" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.credential.arn]
  }
}
