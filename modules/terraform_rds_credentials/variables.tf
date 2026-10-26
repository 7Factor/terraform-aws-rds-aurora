# Required variables
variable "database_type" {
  type        = string
  description = "The kind of database the cluster runs: \"mysql\" (aurora / aurora-mysql) or \"postgres\" (aurora-postgresql). Decides which provider creates the user."

  validation {
    condition     = contains(["mysql", "postgres"], var.database_type)
    error_message = "The database_type value must be \"mysql\" or \"postgres\"."
  }
}

variable "database_identifier" {
  type        = string
  description = "The cluster identifier of the database to create the credential in. Use the main module's db_cluster_id output."
}

variable "name" {
  type        = string
  description = "The name of the credential. Used as both the database username and the Secrets Manager secret name. MySQL usernames can be at most 32 characters."
}

# Optional variables
variable "privileges" {
  type        = list(string)
  default     = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  description = "What the user gets on the database (on its tables, for PostgreSQL). Defaults to SELECT, INSERT, UPDATE and DELETE."

  validation {
    condition     = length(var.privileges) > 0
    error_message = "The privileges value must contain at least one privilege."
  }
}

variable "recovery_window_in_days" {
  type        = number
  default     = 30
  description = "Days Secrets Manager waits before deleting the secret once it's removed. Can be 0 (delete immediately) or 7 to 30. While a secret is waiting to be deleted, a new one with the same name can't be created, so 0 is handy for throwaway environments. Defaults to 30."

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "The recovery_window_in_days value must be 0 or between 7 and 30."
  }
}

variable "schema" {
  type        = string
  default     = "public"
  description = "PostgreSQL only: the schema the user is granted access to. Defaults to public."
}
