resource "aws_secretsmanager_secret" "credentials" {
  name                    = var.secret_name
  description             = var.secret_description
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = var.tags
}

# The secret value uses the same JSON keys as RDS-managed secrets, so anything that already knows how to read those
# (rotation lambdas, drivers, etc.) can read these too.
resource "aws_secretsmanager_secret_version" "credentials" {
  secret_id     = aws_secretsmanager_secret.credentials.id
  secret_string = jsonencode(var.credentials)
}

data "aws_iam_policy_document" "read_credentials" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.credentials.arn]
  }
}
