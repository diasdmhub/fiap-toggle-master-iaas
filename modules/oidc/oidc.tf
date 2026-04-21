# OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "git" {
  url             = "${var.git_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["${var.git_thumbprint}"]
}

# IAM Role
resource "aws_iam_role" "git_actions" {
  name               = "${var.name_prefix}-git-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.git.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:${var.git_org}/${var.git_repo}:ref:refs/heads/${var.git_branch}"
          }
        }
      }
    ]
  })
}

# Anexar politica ECR
resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.git_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}