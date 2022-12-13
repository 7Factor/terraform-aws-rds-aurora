terraform {
  required_version = ">=1.1"
}

# Look up the primary VPC
data "aws_vpc" "primary_vpc" {
  id = var.vpc_id
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier          = "${var.db_name}-aurora-cluster"
  engine                      = var.engine
  engine_version              = var.engine_version
  storage_encrypted           = var.storage_encrypted
  allow_major_version_upgrade = var.allow_major_version_upgrade

  final_snapshot_identifier    = "${var.db_name}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmmssZ", timestamp())}"
  skip_final_snapshot          = var.skip_final_snapshot
  deletion_protection          = var.deletion_protection
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name

  db_cluster_parameter_group_name = var.cluster_parameter_group_name
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  vpc_security_group_ids = flatten([
    aws_security_group.allow_aurora_access.id,
    var.additional_db_sgs,
  ])

  database_name   = var.db_name
  master_username = var.db_master_username
  master_password = var.db_master_password
  port            = var.db_port
}

resource "aws_rds_cluster_instance" "aurora_db" {
  count              = var.db_instance_count
  identifier         = "${var.db_name}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.cluster_identifier

  publicly_accessible = false

  engine_version = var.engine_version
  engine         = var.engine

  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  instance_class       = var.db_instance_class

  performance_insights_enabled = var.performance_insights_enabled
}
