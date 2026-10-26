output "secret_arn" {
  value       = aws_secretsmanager_secret.credential.arn
  description = "The ARN of the secret."
}

output "secret_name" {
  value       = aws_secretsmanager_secret.credential.name
  description = "The name of the secret."
}

output "read_policy_json" {
  value       = data.aws_iam_policy_document.read_credential.json
  description = "An IAM policy document that allows reading the secret."
}
