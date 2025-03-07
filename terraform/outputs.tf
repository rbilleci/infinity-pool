output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "aurora_endpoint" {
  description = "Aurora Serverless cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}
