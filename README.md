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
