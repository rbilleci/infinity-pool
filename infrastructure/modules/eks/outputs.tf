output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "The Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

output "service_role_arn" {
  description = "Service Role ARN"
  value       = aws_iam_role.service_role.arn
}