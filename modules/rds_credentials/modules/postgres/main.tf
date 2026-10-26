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
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.21"
    }
  }
}

# Look up the cluster for its endpoint, port, database name and master user
data "aws_rds_cluster" "database" {
  cluster_identifier = var.database_identifier

  lifecycle {
    postcondition {
      condition     = contains(["aurora-postgresql", "postgres"], self.engine)
      error_message = "The cluster's engine is ${self.engine}, not PostgreSQL. Use the rds_credentials mysql submodule for MySQL clusters."
    }
  }
}

locals {
  database = data.aws_rds_cluster.database.database_name

  # Inserting into serial/identity columns needs USAGE on their sequences. Read-only users only get SELECT.
  sequence_privileges = contains(var.privileges, "INSERT") ? ["USAGE", "SELECT"] : ["SELECT"]
}

resource "random_password" "credential" {
  length  = 32
  special = false
}

resource "postgresql_role" "credential" {
  name     = var.name
  login    = true
  password = random_password.credential.result

  lifecycle {
    precondition {
      condition     = length(var.name) <= 63
      error_message = "PostgreSQL role names can be at most 63 characters. \"${var.name}\" is ${length(var.name)}."
    }
  }
}

resource "postgresql_grant" "database" {
  role        = postgresql_role.credential.name
  database    = local.database
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "schema" {
  role        = postgresql_role.credential.name
  database    = local.database
  schema      = var.schema
  object_type = "schema"
  privileges  = ["USAGE"]
}

# Unlike MySQL, these only cover tables and sequences that exist right now. The default privileges below cover ones
# the master user creates later, since migrations usually run as master.
resource "postgresql_grant" "tables" {
  role        = postgresql_role.credential.name
  database    = local.database
  schema      = var.schema
  object_type = "table"
  privileges  = var.privileges
}

resource "postgresql_grant" "sequences" {
  role        = postgresql_role.credential.name
  database    = local.database
  schema      = var.schema
  object_type = "sequence"
  privileges  = local.sequence_privileges
}

resource "postgresql_default_privileges" "tables" {
  role        = postgresql_role.credential.name
  database    = local.database
  schema      = var.schema
  owner       = data.aws_rds_cluster.database.master_username
  object_type = "table"
  privileges  = var.privileges
}

resource "postgresql_default_privileges" "sequences" {
  role        = postgresql_role.credential.name
  database    = local.database
  schema      = var.schema
  owner       = data.aws_rds_cluster.database.master_username
  object_type = "sequence"
  privileges  = local.sequence_privileges
}

module "secret" {
  source = "../.."

  name                    = var.name
  recovery_window_in_days = var.recovery_window_in_days
  credential = {
    engine   = "postgres"
    host     = data.aws_rds_cluster.database.endpoint
    port     = data.aws_rds_cluster.database.port
    dbname   = local.database
    username = postgresql_role.credential.name
    password = random_password.credential.result
  }
}
