variable "db_cluster_identifier" {
  description = "Database Cluster Identifier"
  type        = string
  default     = "infinity-pool-db"
}

variable "db_subnets" {
  description = "Database subnets"
  type = set(string)
}

variable "private_subnets" {
  description = "Private subnets"
  type = set(string)
}

variable "vpc_id" {
  description = "VPC ID for the cluster."
  type        = string
}