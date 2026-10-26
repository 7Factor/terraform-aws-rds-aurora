terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3"
    }
  }
}

resource "aws_secretsmanager_secret" "credential" {
  name                    = var.name
  recovery_window_in_days = var.recovery_window_in_days
}

# Uses the same JSON keys as RDS-managed secrets, so anything that already knows how to read those (rotation lambdas,
# drivers, etc.) can read these too
resource "aws_secretsmanager_secret_version" "credential" {
  secret_id     = aws_secretsmanager_secret.credential.id
  secret_string = jsonencode(var.credential)
}

data "aws_iam_policy_document" "read_credential" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.credential.arn]
  }
}
