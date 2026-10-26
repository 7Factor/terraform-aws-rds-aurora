# Required variables
variable "username" {
  description = "The name of the MySQL user to create."
  type        = string
}

variable "database" {
  description = "The database the user is granted access to. Grants apply to every table in it, including ones created later."
  type        = string
}

variable "db_host" {
  description = "The endpoint clients connect to, usually the cluster endpoint. This is only written to the secret; the mysql provider config decides how terraform itself connects."
  type        = string
}

# Optional variables
variable "db_port" {
  description = "The port clients connect to. Defaults to 3306."
  type        = number
  default     = 3306
}

variable "privileges" {
  description = "The privileges to grant on the database. Defaults to SELECT, INSERT, UPDATE and DELETE, which is enough for an app that doesn't run its own migrations."
  type        = list(string)
  default     = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  validation {
    condition     = length(var.privileges) > 0
    error_message = "The privileges value must contain at least one privilege."
  }
}

variable "user_host" {
  description = "The host the user is allowed to connect from. Defaults to \"%\" (anywhere); network access is still controlled by the cluster's security groups."
  type        = string
  default     = "%"
}

variable "password_length" {
  description = "The length of the generated password. Defaults to 32."
  type        = number
  default     = 32
}
