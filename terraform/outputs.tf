output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "db_host" {
  description = "Aurora Serverless cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "db_port" {
  description = "Aurora Serverless cluster endpoint"
  value       = aws_rds_cluster.aurora.port
}