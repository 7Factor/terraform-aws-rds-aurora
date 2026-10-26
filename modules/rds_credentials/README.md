# RDS Credentials submodule for RDS Aurora

Gives an app or a person its own database login instead of the master user. Each credential is a database user with a
generated password and the privileges you ask for, plus an AWS Secrets Manager secret holding the credentials, which
whatever uses them reads instead of having a password passed around in CI variables.

Use the submodule for your cluster's engine, once per credential:

* [`modules/mysql`](modules/mysql/README.md) for `aurora` / `aurora-mysql`
* [`modules/postgres`](modules/postgres/README.md) for `aurora-postgresql`

```hcl-terraform
module "api_credentials" {
  source  = "7Factor/rds-aurora/aws//modules/rds_credentials/modules/mysql"
  version = "~> 2"

  database_identifier = module.rds_cluster.db_cluster_id
  name                = "myapp-api-app-user"
  privileges          = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}
```

Each submodule only requires its own database provider (`petoju/mysql` or `cyrilgdn/postgresql`), so you never download
or configure one you don't use. Both use this module to store the secret, with the same JSON keys as RDS-managed
secrets: `engine`, `host`, `port`, `dbname`, `username` and `password`. You don't need to call this module directly.
