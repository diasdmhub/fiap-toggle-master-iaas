output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of all public subnet IDs (in AZ order)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of all private subnet IDs (in AZ order)"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "availability_zones" {
  description = "Availability zones used for subnets"
  value       = local.azs
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = local.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = local.private_subnet_cidrs
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value = aws_eks_cluster.main.endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value = aws_eks_cluster.main.name
}

output "ecr_repository_urls" {
  description = "Lista de URLs dos repositórios ECR"
  value = {
    for name, repo in aws_ecr_repository.toggle :
    name => repo.repository_url
  }
}

output "sqs_queue_url" {
  description = "URL da fila SQS"
  value       = aws_sqs_queue.toggle.url
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  value       = aws_dynamodb_table.toggle.name
}

output "rds_endpoint" {
  description = "Endpoint do RDS (hostname:porta)"
  value       = aws_db_instance.main.endpoint
}

output "rds_connection_url" {
  description = "URL completa de conexão PostgreSQL pronta para uso"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
  sensitive   = true
}

output "rds_security_group_id" {
  description = "ID do Security Group do RDS"
  value       = aws_security_group.rds.id
}