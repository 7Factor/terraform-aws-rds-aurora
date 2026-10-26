output "secret_arn" {
  value       = module.secret.secret_arn
  description = "The ARN of the secret holding the credential. Use this as the valueFrom of an ECS container secret, e.g. \"<arn>:password::\"."
}

output "secret_name" {
  value       = module.secret.secret_name
  description = "The name of the secret holding the credential."
}

output "username" {
  value       = mysql_user.credential.user
  description = "The MySQL username."
}

output "read_policy_json" {
  value       = module.secret.read_policy_json
  description = "An IAM policy document that allows reading the secret. Attach it to whatever needs the credential, like an ECS task execution role."
}
