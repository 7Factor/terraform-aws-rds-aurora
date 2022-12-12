# Renames the old "deletable" instance resource name to the new instance resource name
moved {
  from = aws_rds_cluster_instance.aurora_db_delete
  to   = aws_rds_cluster_instance.aurora_db
}

# Renames the old "undeletable" instance resource name to the new instance resource name
moved {
  from = aws_rds_cluster_instance.aurora_db_no_delete
  to   = aws_rds_cluster_instance.aurora_db
}
