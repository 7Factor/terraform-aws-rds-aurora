locals {
  is_postgres = var.database_type == "postgres"

  # Inserting into serial/identity columns needs USAGE on their sequences. Read-only users only get SELECT.
  sequence_privileges = contains(var.privileges, "INSERT") ? ["USAGE", "SELECT"] : ["SELECT"]
}

resource "postgresql_role" "credential" {
  count = local.is_postgres ? 1 : 0

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
  count = local.is_postgres ? 1 : 0

  role        = postgresql_role.credential[0].name
  database    = data.aws_rds_cluster.database.database_name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "schema" {
  count = local.is_postgres ? 1 : 0

  role        = postgresql_role.credential[0].name
  database    = data.aws_rds_cluster.database.database_name
  schema      = var.schema
  object_type = "schema"
  privileges  = ["USAGE"]
}

# Unlike MySQL, these only cover tables and sequences that exist right now. The default privileges below cover ones
# the master user creates later, since migrations usually run as master.
resource "postgresql_grant" "tables" {
  count = local.is_postgres ? 1 : 0

  role        = postgresql_role.credential[0].name
  database    = data.aws_rds_cluster.database.database_name
  schema      = var.schema
  object_type = "table"
  privileges  = var.privileges
}

resource "postgresql_grant" "sequences" {
  count = local.is_postgres ? 1 : 0

  role        = postgresql_role.credential[0].name
  database    = data.aws_rds_cluster.database.database_name
  schema      = var.schema
  object_type = "sequence"
  privileges  = local.sequence_privileges
}

resource "postgresql_default_privileges" "tables" {
  count = local.is_postgres ? 1 : 0

  role        = postgresql_role.credential[0].name
  database    = data.aws_rds_cluster.database.database_name
  schema      = var.schema
  owner       = data.aws_rds_cluster.database.master_username
  object_type = "table"
  privileges  = var.privileges
}

resource "postgresql_default_privileges" "sequences" {
  count = local.is_postgres ? 1 : 0

  role        = postgresql_role.credential[0].name
  database    = data.aws_rds_cluster.database.database_name
  schema      = var.schema
  owner       = data.aws_rds_cluster.database.master_username
  object_type = "sequence"
  privileges  = local.sequence_privileges
}
