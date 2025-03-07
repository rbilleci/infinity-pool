variable "environment" {
  description = "Environment"
  type        = string
  default     = "development"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "infinity-pool-eks-cluster"
}

variable "aurora_cluster_identifier" {
  description = "Aurora Cluster Identifier"
  type        = string
  default     = "infinity-pool-db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
