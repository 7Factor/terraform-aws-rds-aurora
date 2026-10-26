variable "name" {
  type        = string
  description = "The name of the Secrets Manager secret."
}

variable "credential" {
  type = object({
    engine   = string
    host     = string
    port     = number
    dbname   = string
    username = string
    password = string
  })
  sensitive   = true
  description = "The credential to store."
}

variable "recovery_window_in_days" {
  type        = number
  default     = 30
  description = "Days Secrets Manager waits before deleting the secret once it's removed. Can be 0 (delete immediately) or 7 to 30. Defaults to 30."

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "The recovery_window_in_days value must be 0 or between 7 and 30."
  }
}
