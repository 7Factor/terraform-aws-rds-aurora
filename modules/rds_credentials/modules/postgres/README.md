# PostgreSQL submodule for RDS Credentials

Creates one set of database credentials in an existing Aurora PostgreSQL cluster: a login role with a generated
password and the privileges you ask for, plus an AWS Secrets Manager secret holding the credentials. Whatever uses
them (an app, a person, a reporting tool) reads the secret instead of having a password passed around in CI variables.

Call it once per credential you want. For Aurora MySQL, use the [`mysql` submodule](../mysql/README.md)
instead. Each module only requires its own database provider, so you never download or configure one you don't use.

The secret uses the same JSON keys as RDS-managed secrets: `engine`, `host`, `port`, `dbname`, `username` and
`password`.

## Prerequisites

Creating a role means **terraform has to connect to the database when you plan and apply.** Configure the
[cyrilgdn/postgresql](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs) provider in your own
root module, logged in as a user that can create other roles (usually the master user), with `superuser = false` since
the RDS master user isn't a real superuser. The module uses it implicitly.

If the database is in private subnets, give the provider a way in, such as an SSH port forward through a bastion host.

Because the provider connects at plan time, the cluster must already exist. When building a brand new environment,
apply the cluster first (`terraform apply -target=module.rds_cluster`), then everything else.

## Example Usage

```hcl-terraform
terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.21"
    }
  }
}

# Connects through an SSH port forward to the cluster on localhost:5432
provider "postgresql" {
  host      = "127.0.0.1"
  port      = 5432
  username  = "myapp"
  password  = var.db_password
  superuser = false
}

module "rds_cluster" {
  source  = "7Factor/rds-aurora/aws"
  version = "~> 2"

  engine = "aurora-postgresql"
  # ...cluster settings...
}

module "api_credentials" {
  source  = "7Factor/rds-aurora/aws//modules/rds_credentials/modules/postgres"
  version = "~> 2"

  database_identifier = module.rds_cluster.db_cluster_id
  name                = "myapp-api-app-user"
  privileges          = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}
```

See the [`mysql` submodule readme](../mysql/README.md#reading-the-secret-from-ecs) for reading
the secret from ECS; it works the same way.

## Things to know

* `name` is both the role name and the secret name. Role names can be at most 63 characters.
* `privileges` apply to the tables in `schema` (default `public`). The role also gets them on tables the master user
  creates later, since migrations usually run as master. It gets `USAGE` on sequences too when `privileges` includes
  `INSERT`, which inserting into serial/identity columns needs.
* The module checks the cluster's engine and fails the plan if it isn't PostgreSQL.
* The generated password is stored in terraform state, so treat your state bucket like it holds secrets.
* Removing the module block drops the role and schedules the secret for deletion. Use `recovery_window_in_days = 0` for
  throwaway environments so the name can be reused right away.
* To change the password, replace it, e.g.
  `terraform apply -replace='module.api_credentials.random_password.credential'`, then redeploy whatever uses it.
