output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value = aws_eks_cluster.main.name
}