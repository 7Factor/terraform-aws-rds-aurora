terraform {
  required_version = ">= 1.3.0"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.21"
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

resource "postgresql_role" "credential" {
  name     = var.username
  login    = true
  password = random_password.credential.result
}

resource "postgresql_grant" "database" {
  role        = postgresql_role.credential.name
  database    = var.database
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_grant" "schema" {
  role        = postgresql_role.credential.name
  database    = var.database
  schema      = var.schema
  object_type = "schema"
  privileges  = ["USAGE"]
}

# Unlike MySQL, these only cover tables and sequences that exist right now. See the default privileges below for
# anything created later.
resource "postgresql_grant" "tables" {
  role        = postgresql_role.credential.name
  database    = var.database
  schema      = var.schema
  object_type = "table"
  privileges  = var.table_privileges
}

resource "postgresql_grant" "sequences" {
  count = length(var.sequence_privileges) > 0 ? 1 : 0

  role        = postgresql_role.credential.name
  database    = var.database
  schema      = var.schema
  object_type = "sequence"
  privileges  = var.sequence_privileges
}

resource "postgresql_default_privileges" "tables" {
  count = var.objects_owner != null ? 1 : 0

  role        = postgresql_role.credential.name
  database    = var.database
  schema      = var.schema
  owner       = var.objects_owner
  object_type = "table"
  privileges  = var.table_privileges
}

resource "postgresql_default_privileges" "sequences" {
  count = var.objects_owner != null && length(var.sequence_privileges) > 0 ? 1 : 0

  role        = postgresql_role.credential.name
  database    = var.database
  schema      = var.schema
  owner       = var.objects_owner
  object_type = "sequence"
  privileges  = var.sequence_privileges
}
