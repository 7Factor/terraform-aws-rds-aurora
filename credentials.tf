# Optional database credentials. For each name in var.credentials this creates a database user with a generated
# password and a Secrets Manager secret holding its credentials. With the default empty list nothing here is created
# and no database connection is needed.
#
# Creating users means connecting to the database, so the caller has to configure the matching provider (petoju/mysql
# or cyrilgdn/postgresql) with credentials that can create users. See the README.

locals {
  # Flattens the groups into one map of username => settings
  credentials = merge({}, [
    for group in var.credentials : {
      for name in group.names : name => {
        secret_name             = format(group.name_format, name)
        privileges              = group.privileges
        recovery_window_in_days = group.recovery_window_in_days
      }
    }
  ]...)

  is_postgres          = var.engine == "aurora-postgresql"
  mysql_credentials    = local.is_postgres ? {} : local.credentials
  postgres_credentials = local.is_postgres ? local.credentials : {}
}

module "mysql_credential" {
  source   = "./modules/db_credential/modules/mysql_credentials"
  for_each = local.mysql_credentials

  username   = each.key
  database   = aws_rds_cluster.aurora_cluster.database_name
  db_host    = aws_rds_cluster.aurora_cluster.endpoint
  db_port    = aws_rds_cluster.aurora_cluster.port
  privileges = each.value.privileges
}

module "postgres_credential" {
  source   = "./modules/db_credential/modules/postgres_credentials"
  for_each = local.postgres_credentials

  username         = each.key
  database         = aws_rds_cluster.aurora_cluster.database_name
  db_host          = aws_rds_cluster.aurora_cluster.endpoint
  db_port          = aws_rds_cluster.aurora_cluster.port
  table_privileges = each.value.privileges

  # Migrations usually run as the master user, so grant on the tables it creates later too
  objects_owner = var.db_master_username
}

module "credential_secret" {
  source   = "./modules/db_credential"
  for_each = local.credentials

  secret_name             = each.value.secret_name
  credentials             = merge(module.mysql_credential, module.postgres_credential)[each.key]
  recovery_window_in_days = each.value.recovery_window_in_days
}
