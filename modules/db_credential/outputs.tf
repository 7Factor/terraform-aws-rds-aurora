output "secret_arn" {
  description = "The ARN of the secret holding the credentials. Use this as the valueFrom of an ECS container secret, e.g. \"<arn>:password::\"."
  value       = aws_secretsmanager_secret.credentials.arn
}

output "secret_name" {
  description = "The name of the secret holding the credentials."
  value       = aws_secretsmanager_secret.credentials.name
}

output "read_policy_json" {
  description = "An IAM policy document that allows reading the secret. Attach it to whatever needs the credentials, like an ECS task execution role."
  value       = data.aws_iam_policy_document.read_credentials.json
}
