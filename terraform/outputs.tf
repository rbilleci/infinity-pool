output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "db_host" {
  description = "Aurora DNS Name"
  value       = aws_route53_record.aurora_db.fqdn
}

output "svc_role_arn" {
  value = aws_iam_role.svc_role.arn
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "eks_cluster_primary_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}