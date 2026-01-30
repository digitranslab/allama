output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.allama.endpoint
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.allama.name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the EKS cluster"
  value       = aws_eks_cluster.allama.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.allama.arn
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.allama.endpoint
}

output "rds_address" {
  description = "RDS PostgreSQL address (hostname only)"
  value       = aws_db_instance.allama.address
}

output "rds_identifier" {
  description = "RDS PostgreSQL instance identifier"
  value       = aws_db_instance.allama.identifier
}

output "elasticache_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_replication_group.allama.primary_endpoint_address
}

output "s3_attachments_bucket" {
  description = "S3 bucket name for attachments"
  value       = aws_s3_bucket.attachments.id
}

output "s3_registry_bucket" {
  description = "S3 bucket name for registry"
  value       = aws_s3_bucket.registry.id
}

output "allama_url" {
  description = "URL for accessing Allama"
  value       = "https://${var.domain_name}"
}

output "allama_namespace" {
  description = "Kubernetes namespace where Allama is deployed"
  value       = kubernetes_namespace.allama.metadata[0].name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "s3_access_role_arn" {
  description = "ARN of the IAM role for S3 access (IRSA)"
  value       = aws_iam_role.allama_s3.arn
}
