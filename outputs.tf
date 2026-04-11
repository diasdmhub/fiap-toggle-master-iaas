######################
# Principais outputs #
######################
output "vpc_outputs" {
  value       = module.vpc
  description = "Outputs do modulo VPC"
}

output "eks_outputs" {
  value       = module.eks
  description = "Outputs do modulo EKS"
}

output "rds_outputs" {
  value       = module.rds
  description = "Outputs do modulo RDS"
}

output "cache_outputs" {
  value       = module.cache
  description = "Outputs do modulo Cache"
}

output "dynamo_outputs" {
  value       = module.dynamo
  description = "Outputs do modulo Dynamo"
}

output "ecr_outputs" {
  value       = module.ecr
  description = "Outputs do modulo ECR"
}

output "sqs_outputs" {
  value       = module.sqs
  description = "Outputs do modulo SQS"
}