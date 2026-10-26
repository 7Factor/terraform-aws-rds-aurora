resource "aws_secretsmanager_secret" "credential" {
  name                    = var.name
  recovery_window_in_days = var.recovery_window_in_days
}

# Uses the same JSON keys as RDS-managed secrets, so anything that already knows how to read those (rotation lambdas,
# drivers, etc.) can read these too
resource "aws_secretsmanager_secret_version" "credential" {
  secret_id = aws_secretsmanager_secret.credential.id
  secret_string = jsonencode({
    engine   = var.database_type
    host     = data.aws_rds_cluster.database.endpoint
    port     = data.aws_rds_cluster.database.port
    dbname   = data.aws_rds_cluster.database.database_name
    username = local.is_postgres ? postgresql_role.credential[0].name : mysql_user.credential[0].user
    password = random_password.credential.result
  })
}

data "aws_iam_policy_document" "read_credential" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.credential.arn]
  }
}
