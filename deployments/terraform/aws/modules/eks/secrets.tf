# Kubernetes Namespace for Allama
resource "kubernetes_namespace" "allama" {
  metadata {
    name   = "allama"
    labels = local.common_labels
  }

  depends_on = [aws_eks_node_group.allama]
}

# Note: K8s secrets are now created by External Secrets Operator via the Helm chart.
# This avoids exposing secret values in Terraform state.
#
# The Helm chart's ExternalSecret resources sync from AWS Secrets Manager:
# - allama-secrets: Core credentials (dbEncryptionKey, serviceKey, signingSecret, userAuthSecret)
# - allama-postgres-credentials: RDS credentials (username, password)
# - allama-redis-credentials: Redis URL

# Redis URL stored in AWS Secrets Manager (for ESO to sync)
# This creates the secret in AWS, not K8s - ESO handles the K8s secret creation
locals {
  redis_url = "rediss://:${random_password.redis_auth.result}@${aws_elasticache_replication_group.allama.primary_endpoint_address}:6379"
}

resource "aws_secretsmanager_secret" "redis_url" {
  name        = "allama/redis-${random_id.s3_suffix.hex}"
  description = "Redis URL for Allama"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_url" {
  secret_id                = aws_secretsmanager_secret.redis_url.id
  secret_string_wo         = local.redis_url
  secret_string_wo_version = parseint(substr(md5(local.redis_url), 0, 8), 16)
}
