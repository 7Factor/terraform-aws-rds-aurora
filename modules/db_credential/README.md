# DB Credential submodule for RDS Aurora

This submodule stores one set of database credentials in an AWS Secrets Manager secret, so whatever uses them can read
them at runtime (for example through an ECS container `secrets` block) instead of having a password passed around in CI
variables.

The main module's `credentials` variable is the easy way to use this; see the main module's readme. You only need this
submodule directly to manage credentials for a database the main module didn't create.

The work is split in two:

* A **credentials submodule** creates the user in the database, generates its password and grants it access. Pick the
  one that matches your engine:
  * `modules/mysql_credentials` (MySQL / Aurora MySQL)
  * `modules/postgres_credentials` (PostgreSQL / Aurora PostgreSQL)
* **This module** takes the credentials submodule's output and stores it in Secrets Manager. It doesn't care which
  engine produced it.

The secret uses the same JSON keys as RDS-managed secrets: `engine`, `host`, `port`, `dbname`, `username` and
`password`.

## Example Usage

```hcl-terraform
module "reporting_mysql_credentials" {
  source  = "7Factor/rds-aurora/aws//modules/db_credential/modules/mysql_credentials"
  version = "~> 2.2"

  username   = "myapp_reporting"
  database   = "myapp"
  db_host    = "myapp.cluster-abc123.us-east-1.rds.amazonaws.com"
  privileges = ["SELECT"]
}

module "reporting_credential" {
  source  = "7Factor/rds-aurora/aws//modules/db_credential"
  version = "~> 2.2"

  secret_name = "myapp-reporting"
  credentials = module.reporting_mysql_credentials
}
```

The `mysql` provider has to be configured in your root module, the same way the main module's readme describes.
