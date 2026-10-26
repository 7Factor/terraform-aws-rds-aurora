# Required variables
variable "database_identifier" {
  type        = string
  description = "The cluster identifier of the PostgreSQL database to create the credential in. Use the main module's db_cluster_id output."
}

variable "name" {
  type        = string
  description = "The name of the credential. Used as both the PostgreSQL role name and the Secrets Manager secret name. Role names can be at most 63 characters."
}

# Optional variables
variable "privileges" {
  type        = list(string)
  default     = ["SELECT", "INSERT", "UPDATE", "DELETE"]
  description = "What the role gets on the tables in schema, including tables the master user creates later. Defaults to SELECT, INSERT, UPDATE and DELETE."

  validation {
    condition     = length(var.privileges) > 0
    error_message = "The privileges value must contain at least one privilege."
  }
}

variable "schema" {
  type        = string
  default     = "public"
  description = "The schema the role is granted access to. Defaults to public."
}

variable "recovery_window_in_days" {
  type        = number
  default     = 30
  description = "Days Secrets Manager waits before deleting the secret once it's removed. Can be 0 (delete immediately) or 7 to 30. While a secret is waiting to be deleted, a new one with the same name can't be created, so 0 is handy for throwaway environments. Defaults to 30."
}
