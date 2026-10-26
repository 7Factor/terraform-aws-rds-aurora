# Optional database credentials. For each username in var.credentials this creates a database user with a generated
# password and a Secrets Manager secret holding its credentials. With the default empty list nothing here is created
# and no database connection is needed.
#
# Creating users means connecting to the database, so the caller has to configure the matching provider (petoju/mysql
# or cyrilgdn/postgresql) with credentials that can create users. See the README.

locals {
  credentials          = toset(var.credentials)
  is_postgres          = var.engine == "aurora-postgresql"
  mysql_credentials    = local.is_postgres ? toset([]) : local.credentials
  postgres_credentials = local.is_postgres ? local.credentials : toset([])
}

module "mysql_credential" {
  source   = "./modules/db_credential/modules/mysql_credentials"
  for_each = local.mysql_credentials

  username   = each.key
  database   = aws_rds_cluster.aurora_cluster.database_name
  db_host    = aws_rds_cluster.aurora_cluster.endpoint
  db_port    = aws_rds_cluster.aurora_cluster.port
  privileges = var.credential_privileges
}

module "postgres_credential" {
  source   = "./modules/db_credential/modules/postgres_credentials"
  for_each = local.postgres_credentials

  username         = each.key
  database         = aws_rds_cluster.aurora_cluster.database_name
  db_host          = aws_rds_cluster.aurora_cluster.endpoint
  db_port          = aws_rds_cluster.aurora_cluster.port
  table_privileges = var.credential_privileges

  # Migrations usually run as the master user, so grant on the tables it creates later too
  objects_owner = var.db_master_username
}

module "credential_secret" {
  source   = "./modules/db_credential"
  for_each = local.credentials

  secret_name             = format(var.credential_secret_name_format, each.key)
  credentials             = merge(module.mysql_credential, module.postgres_credential)[each.key]
  recovery_window_in_days = var.credential_secret_recovery_window_in_days
}
