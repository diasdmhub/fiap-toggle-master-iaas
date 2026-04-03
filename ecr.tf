resource "aws_ecr_repository" "service" {
  for_each = var.service_list

  name                 = "toggle/${each.value}-service"
  image_tag_mutability = "MUTABLE"
  tags = {
    Toggle  = "ECR"
    Service = "${var.name_prefix}-ecr-${each.value}"
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}