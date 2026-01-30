# SecurityGroupPolicy CRDs are installed by the VPC CNI addon
# Using null_resource with kubectl because kubernetes_manifest has CRD timing issues

resource "null_resource" "allama_postgres_sg_policy" {
  triggers = {
    namespace       = kubernetes_namespace.allama.metadata[0].name
    security_group  = aws_security_group.allama_postgres_client.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
apiVersion: vpcresources.k8s.aws/v1beta1
kind: SecurityGroupPolicy
metadata:
  name: allama-postgres-access
  namespace: ${kubernetes_namespace.allama.metadata[0].name}
  labels:
    app.kubernetes.io/managed-by: terraform
    app.kubernetes.io/part-of: allama
spec:
  podSelector:
    matchLabels:
      allama.com/access-postgres: "true"
  securityGroups:
    groupIds:
      - ${aws_security_group.allama_postgres_client.id}
EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete securitygrouppolicy allama-postgres-access -n ${self.triggers.namespace} --ignore-not-found"
  }

  depends_on = [aws_eks_addon.vpc_cni, kubernetes_namespace.allama]
}

resource "null_resource" "allama_redis_sg_policy" {
  triggers = {
    namespace       = kubernetes_namespace.allama.metadata[0].name
    security_group  = aws_security_group.allama_redis_client.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      cat <<EOF | kubectl apply -f -
apiVersion: vpcresources.k8s.aws/v1beta1
kind: SecurityGroupPolicy
metadata:
  name: allama-redis-access
  namespace: ${kubernetes_namespace.allama.metadata[0].name}
  labels:
    app.kubernetes.io/managed-by: terraform
    app.kubernetes.io/part-of: allama
spec:
  podSelector:
    matchLabels:
      allama.com/access-redis: "true"
  securityGroups:
    groupIds:
      - ${aws_security_group.allama_redis_client.id}
EOF
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete securitygrouppolicy allama-redis-access -n ${self.triggers.namespace} --ignore-not-found"
  }

  depends_on = [aws_eks_addon.vpc_cni, kubernetes_namespace.allama]
}
