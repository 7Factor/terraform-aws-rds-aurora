output "secret_arn" {
  value       = aws_secretsmanager_secret.credential.arn
  description = "The ARN of the secret holding the credential. Use this as the valueFrom of an ECS container secret, e.g. \"<arn>:password::\"."
}

output "secret_name" {
  value       = aws_secretsmanager_secret.credential.name
  description = "The name of the secret holding the credential."
}

output "username" {
  value       = var.name
  description = "The database username."
}

output "read_policy_json" {
  value       = data.aws_iam_policy_document.read_credential.json
  description = "An IAM policy document that allows reading the secret. Attach it to whatever needs the credential, like an ECS task execution role."
}
