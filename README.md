# RDS Aurora via Terraform

This module will allow you to deploy an RDS Aurora cluster.

## Prerequisites

First, you need a decent understanding of how to use Terraform. [Hit the docs](https://www.terraform.io/intro/index.html) for that.
Then, you should familiarize yourself with ECS [concepts](https://aws.amazon.com/ecs/getting-started/), especially if you've
never worked with a clustering solution before. Once you're good, import this module and
pass the appropriate variables. Then, plan your run and deploy.

## Example Usage

```hcl-terraform
resource "aws_rds_cluster_parameter_group" "cluster_parameter_group" {
  name        = "myapp${var.env_name}-cluster-parameter-group"
  family      = var.family
  description = "Parameters for my app's RDS cluster."

  parameter {
    name         = "binlog_format"
    value        = "MIXED"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_bin_trust_function_creators"
    value        = 1
    apply_method = "pending-reboot"
  }
}

module "rds_cluster" {
  source  = "7factor/rds-aurora/aws"
  version = "~> 1"

  db_instance_count = 2

  vpc_id = var.vpc_id

  allow_db_access_sgs = [
    var.ecs_sg,
    var.bastion_sg,
  ]

  primary_db_subnets = var.primary_db_subnets

  db_name                      = "myapp${var.env_name}"
  db_instance_class            = var.db_config.db_instance_class
  db_master_username           = "myapp"
  db_master_password           = var.db_password
  db_port                      = 3306
  storage_encrypted            = true
  cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_parameter_group.name
  performance_insights_enabled = var.performance_insights_enabled
}
```

## Database credentials

The module can optionally create database credentials, for example a login per app so apps don't use the master user,
or read-only logins for people. Pass groups of usernames as `credentials`; each group has its own settings:

| Key                       | Default                                    | Description                                                                 |
|---------------------------|--------------------------------------------|-----------------------------------------------------------------------------|
| `names`                   | (required)                                 | The database usernames to create.                                           |
| `name_format`             | `"%s"`                                     | A `format()` string that turns a username into its secret name.            |
| `privileges`              | `["SELECT", "INSERT", "UPDATE", "DELETE"]` | What the users get on the database (on its tables, for PostgreSQL).         |
| `recovery_window_in_days` | `30`                                       | Days before a removed secret is deleted. `0` (immediately) or `7` to `30`. |

For each name the module creates a database user with a generated password, grants it the group's privileges, and
stores the credentials in a Secrets Manager secret. The `credential_secret_arns` output maps each username to its
secret's ARN. A name can only appear once across all groups. Leave `credentials` empty (the default) and none of this
is created.

The secret uses the same JSON keys as RDS-managed secrets: `engine`, `host`, `port`, `dbname`, `username` and
`password`.

### Prerequisites

Creating users means **terraform has to connect to the database when you plan and apply.** You configure the provider
in your own root module: `petoju/mysql` for `aurora` / `aurora-mysql`, or `cyrilgdn/postgresql` for
`aurora-postgresql`, logged in as a user that can create other users (usually the master user). If the database is in
private subnets, open an SSH tunnel through a bastion host before running terraform and point the provider at the
tunnel.

Because the provider connects at plan time, the cluster must already exist. When building a brand new environment,
apply the cluster first with an empty `credentials` list (or with `-target`), then add the credentials.

### Example

```hcl-terraform
terraform {
  required_providers {
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3"
    }
  }
}

# Connects through an SSH tunnel to the cluster on localhost:3306
provider "mysql" {
  endpoint = "127.0.0.1:3306"
  username = "myapp"
  password = var.db_password
}

module "rds_cluster" {
  source  = "7factor/rds-aurora/aws"
  version = "~> 2.2"

  # ...the usual cluster settings...

  credentials = [
    {
      # App logins: MySQL users "myapp-api" and "myapp-worker", secrets "myapp-api-app-user" and "myapp-worker-app-user"
      names       = ["myapp-api", "myapp-worker"]
      name_format = "%s-app-user"
    },
    {
      # Read-only logins for people, with secrets that can be recreated sooner after removal
      names                   = ["support", "audit"]
      name_format             = "%s-user"
      privileges              = ["SELECT"]
      recovery_window_in_days = 10
    },
  ]
}
```

For PostgreSQL, configure the `postgresql` provider instead and set `superuser = false` in it, since the RDS master
user isn't a real superuser. PostgreSQL users are also granted on tables the master user creates later, since
migrations usually run as master.

### Reading a secret from ECS

Give the task execution role `secretsmanager:GetSecretValue` on the secret, then reference its keys in the container
definition:

```hcl-terraform
secrets = [
  { name = "DATABASE_USER", valueFrom = "${module.rds_cluster.credential_secret_arns["myapp-api"]}:username::" },
  { name = "DATABASE_PASSWORD", valueFrom = "${module.rds_cluster.credential_secret_arns["myapp-api"]}:password::" },
]
```

ECS only reads the secret when a task starts, so running tasks keep the old password until they're replaced.

### Things to know

* MySQL usernames can be at most 32 characters.
* The generated passwords are stored in terraform state, so treat your state bucket like it holds secrets (it already
  does if your master password is in there).
* Removing a username drops the user and schedules its secret for deletion. A secret waiting to be deleted blocks
  creating a new one with the same name, so set the group's `recovery_window_in_days = 0` for throwaway environments.
* Moving a name to a different group keeps its user and secret; only the changed settings are updated. Changing
  `name_format` renames the secret, which replaces it.
* To change a password, replace it, e.g. for MySQL
  `terraform apply -replace='module.rds_cluster.module.mysql_credential["myapp-api"].random_password.credential'`,
  then redeploy whatever uses it. Anything still using the old password loses access as soon as the apply finishes.

## Migrating from github.com/7factor/terraform-rds-aurora

This is the new home of the terraform-rds-aurora module. It was copied here so that changes wouldn't break services
relying on the old repo. Going forward, you should endeavour to use this version of the module. More specifically, use
the [module from the Terraform registry](https://registry.terraform.io/modules/7Factor/rds-aurora/aws/latest). This way,
you can select a range of versions to use in your service which allows us to make potentially breaking changes to the
module without breaking your service.

### Migration instructions

You need to change the module source from the GitHub url to `7Factor/rds-aurora/aws`. This will pull the module from
the Terraform registry. You should also add a version to the module block. See the [example](#example-usage) above for
what this looks like together.

**Major version 1 is intended to maintain backwards compatibility with the old module source.** To use the new module
source and maintain compatibility, set your version to `"~> 1"`. This means you will receive any updates that are
backwards compatible with the old module.
