output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_ca" {
  description = "Dados do certificado do cluster EKS"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}