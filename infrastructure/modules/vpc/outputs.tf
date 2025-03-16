output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnets"
  value       = module.vpc.private_subnets
}

output "db_subnets" {
  description = "List of database subnets"
  value       = module.vpc.database_subnets
}