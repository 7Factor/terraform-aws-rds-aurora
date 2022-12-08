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
  source = "7factor/rds-aurora/aws"

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
