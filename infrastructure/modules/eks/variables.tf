variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster."
  type        = string
  default     = "1.32"
}

variable "private_subnets" {
  description = "Private subnets for the cluster."
  type = set(string)
}

variable "service_role_name" {
  description = "Service Role Name"
  type        = string
  default     = "infinity-pool-service-role"
}

variable "vpc_id" {
  description = "VPC ID for the cluster."
  type        = string
}
