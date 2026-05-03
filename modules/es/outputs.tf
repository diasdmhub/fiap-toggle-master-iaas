output "external_secrets_role_arn" {
  description = "ARN da IAM Role usada pelo External Secrets Operator"
  value       = aws_iam_role.external_secrets.arn
}

output "external_secrets_namespace" {
  description = "Namespace onde o External Secrets foi instalado"
  value       = kubernetes_namespace_v1.external_secrets.metadata[0].name
}