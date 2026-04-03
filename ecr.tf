resource "aws_ecr_repository" "service" {
  for_each = var.services

  name                 = "toggle/${each.value}-service"
  image_tag_mutability = "MUTABLE"
  tags = {
    Toggle  = "ECR"
    Service = each.value
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}