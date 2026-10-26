# Required variables
variable "username" {
  description = "The name of the PostgreSQL role to create."
  type        = string
}

variable "database" {
  description = "The database the role is granted access to."
  type        = string
}

variable "db_host" {
  description = "The endpoint clients connect to, usually the cluster endpoint. This is only written to the secret; the postgresql provider config decides how terraform itself connects."
  type        = string
}

# Optional variables
variable "db_port" {
  description = "The port clients connect to. Defaults to 5432."
  type        = number
  default     = 5432
}

variable "schema" {
  description = "The schema the role is granted access to. Defaults to public."
  type        = string
  default     = "public"
}

variable "table_privileges" {
  description = "The privileges to grant on tables in the schema. Defaults to SELECT, INSERT, UPDATE and DELETE, which is enough for an app that doesn't run its own migrations."
  type        = list(string)
  default     = ["SELECT", "INSERT", "UPDATE", "DELETE"]

  validation {
    condition     = length(var.table_privileges) > 0
    error_message = "The table_privileges value must contain at least one privilege."
  }
}

variable "sequence_privileges" {
  description = "The privileges to grant on sequences in the schema. Inserting into serial/identity columns needs USAGE. Set to an empty list to skip sequence grants. Defaults to USAGE and SELECT."
  type        = list(string)
  default     = ["USAGE", "SELECT"]
}

variable "objects_owner" {
  description = "The role that creates tables in the schema, usually the one your migrations run as. When set, tables and sequences it creates later get the same grants automatically. Without it, the role only gets access to objects that exist when terraform runs. Defaults to null."
  type        = string
  default     = null
}

variable "password_length" {
  description = "The length of the generated password. Defaults to 32."
  type        = number
  default     = 32
}
