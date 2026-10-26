# Required variables
variable "secret_name" {
  description = "The name of the Secrets Manager secret to store the credentials in. Something like \"myapp/stage/db/api\" works well."
  type        = string
}

variable "credentials" {
  description = "The database credentials to store. See the modules/mysql_credentials and modules/postgres_credentials submodules for a simple way to create this."
  type = object({
    engine   = string
    host     = string
    port     = number
    dbname   = string
    username = string
    password = string
  })
  sensitive = true
}

# Optional variables
variable "secret_description" {
  description = "A description for the secret. Defaults to null."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Number of days Secrets Manager waits before deleting the secret. Can be 0 (delete immediately) or 7 to 30. While a secret is waiting to be deleted, a new secret with the same name can't be created, so 0 is handy for throwaway environments. Defaults to 30."
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "The recovery_window_in_days value must be 0 or between 7 and 30."
  }
}

variable "tags" {
  description = "Tags to assign to the secret. Defaults to none."
  type        = map(string)
  default     = {}
}
