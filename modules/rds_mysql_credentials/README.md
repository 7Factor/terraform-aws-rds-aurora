# MySQL Credentials submodule for RDS Aurora

Creates one set of database credentials in an existing Aurora MySQL cluster: a MySQL user with a generated password and
the privileges you ask for, plus an AWS Secrets Manager secret holding the credentials. Whatever uses them (an app, a
person, a reporting tool) reads the secret instead of having a password passed around in CI variables.

Call it once per credential you want. For Aurora PostgreSQL, use [`rds_postgres_credentials`](../rds_postgres_credentials/README.md)
instead. Each module only requires its own database provider, so you never download or configure one you don't use.

The secret uses the same JSON keys as RDS-managed secrets: `engine`, `host`, `port`, `dbname`, `username` and
`password`.

## Prerequisites

Creating a MySQL user means **terraform has to connect to the database when you plan and apply.** Configure the
[petoju/mysql](https://registry.terraform.io/providers/petoju/mysql/latest/docs) provider in your own root module,
logged in as a user that can create other users (usually the master user). The module uses it implicitly.

If the database is in private subnets, give the provider a way in, such as a SOCKS proxy through a bastion host
(`proxy = "socks5h://127.0.0.1:1080"`) or an SSH port forward.

Because the provider connects at plan time, the cluster must already exist. When building a brand new environment,
apply the cluster first (`terraform apply -target=module.rds_cluster`), then everything else.

## Example Usage

```hcl-terraform
terraform {
  required_providers {
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3"
    }
  }
}

# Connects to the cluster through a SOCKS proxy opened through a bastion host
provider "mysql" {
  endpoint = "${module.rds_cluster.db_endpoint}:${module.rds_cluster.db_port}"
  proxy    = "socks5h://127.0.0.1:1080"
  username = "myapp"
  password = var.db_password
}

module "rds_cluster" {
  source  = "7Factor/rds-aurora/aws"
  version = "~> 2"

  # ...cluster settings...
}

module "api_credentials" {
  source  = "7Factor/rds-aurora/aws//modules/rds_mysql_credentials"
  version = "~> 2"

  database_identifier = module.rds_cluster.db_cluster_id
  name                = "myapp-api-app-user"
  privileges          = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

module "support_credentials" {
  source  = "7Factor/rds-aurora/aws//modules/rds_mysql_credentials"
  version = "~> 2"

  database_identifier     = module.rds_cluster.db_cluster_id
  name                    = "support-user"
  privileges              = ["SELECT"]
  recovery_window_in_days = 10
}
```

### Reading the secret from ECS

Attach `read_policy_json` to the task execution role, then reference the secret's keys in the container definition:

```hcl-terraform
secrets = [
  { name = "DATABASE_USER", valueFrom = "${module.api_credentials.secret_arn}:username::" },
  { name = "DATABASE_PASSWORD", valueFrom = "${module.api_credentials.secret_arn}:password::" },
]
```

ECS only reads the secret when a task starts, so running tasks keep the old password until they're replaced.

## Things to know

* `name` is both the MySQL username and the secret name. MySQL usernames can be at most 32 characters.
* `privileges` apply to the whole database, including tables created later.
* The module checks the cluster's engine and fails the plan if it isn't MySQL.
* The generated password is stored in terraform state, so treat your state bucket like it holds secrets (it already
  does if your master password is in there).
* Removing the module block drops the user and schedules the secret for deletion. A secret waiting to be deleted blocks
  creating a new one with the same name, so use `recovery_window_in_days = 0` for throwaway environments.
* To change the password, replace it, e.g.
  `terraform apply -replace='module.api_credentials.random_password.credential'`, then redeploy whatever uses it.
  Anything still using the old password loses access as soon as the apply finishes.
