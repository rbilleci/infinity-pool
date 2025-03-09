output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "db_host" {
  description = "Aurora DNS Name"
  value       = aws_route53_record.aurora_db.fqdn
}
