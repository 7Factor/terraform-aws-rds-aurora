terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3"
    }
    mysql = {
      source  = "petoju/mysql"
      version = ">= 3"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.21"
    }
  }
}

# Look up the cluster for its endpoint, port and database name
data "aws_rds_cluster" "database" {
  cluster_identifier = var.database_identifier

  lifecycle {
    postcondition {
      condition = (var.database_type == "postgres"
        ? contains(["aurora-postgresql", "postgres"], self.engine)
      : contains(["aurora", "aurora-mysql", "mysql"], self.engine))
      error_message = "The cluster's engine is ${self.engine}, which doesn't match database_type \"${var.database_type}\"."
    }
  }
}

resource "random_password" "credential" {
  length  = 32
  special = false
}
