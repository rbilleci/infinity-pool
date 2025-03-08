output "public_subnets" {
  description = "Public subnets for ALB placement"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Public subnets for ALB placement"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "Public subnets for ALB placement"
  value       = module.vpc.database_subnets
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "aurora_endpoint" {
  description = "Aurora Serverless cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}
