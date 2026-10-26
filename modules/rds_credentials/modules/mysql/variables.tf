# Required variables
variable "database_identifier" {
  type        = string
  description = "The cluster identifier of the MySQL database to create the credential in. Use the main module's db_cluster_id output."
}

variable "name" {
  type        = string
  description = "The name of the credential. Used as both the MySQL username and the Secrets Manager secret name. MySQL usernames can be at most 32 characters."
}

# Optional variables
variable "privileges" {
  type        = list(string)
  default     = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  description = "What the user gets on the database. Applies to every table, including ones created later. Defaults to SELECT, INSERT, UPDATE and DELETE."

  validation {
    condition     = length(var.privileges) > 0
    error_message = "The privileges value must contain at least one privilege."
  }
}

variable "recovery_window_in_days" {
  type        = number
  default     = 30
  description = "Days Secrets Manager waits before deleting the secret once it's removed. Can be 0 (delete immediately) or 7 to 30. While a secret is waiting to be deleted, a new one with the same name can't be created, so 0 is handy for throwaway environments. Defaults to 30."
}
