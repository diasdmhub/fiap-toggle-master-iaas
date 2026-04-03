# EKS cluster IAM role para o control plane
resource "aws_iam_role" "eks_cluster" {
  name = "${var.name_prefix}-eks-cluster-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-eks-cluster-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}


# EKS Node Group IAM role para os nodes
resource "aws_iam_role" "eks_nodes" {
  name = "${var.name_prefix}-eks-cluster-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-eks-cluster-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}


# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.name_prefix}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.35"

  vpc_config {
    # Control plane ENIs in the private subnets
    subnet_ids = aws_subnet.private[*].id
  }

  tags = {
    Name = "${var.name_prefix}-eks-cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}


# EKS Managed Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name_prefix}-eks-cluster-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  # Nodes na subnet pública para acessar o ECR/S3
  subnet_ids = aws_subnet.public[*].id

  instance_types = ["t3.small"]
  disk_size      = 20

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }

  labels = {
    "alpha.eksctl.io/cluster-name" = "${var.name_prefix}-eks-cluster"
  }

  # Opicional: força o update quando o node group mudar
  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.name_prefix}-eks-cluster-nodes"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_nodes_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.main
  ]
}


# EKS Add-ons
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  depends_on = [aws_eks_cluster.main, aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  depends_on = [aws_eks_cluster.main, aws_eks_node_group.main]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  depends_on = [aws_eks_cluster.main, aws_eks_node_group.main]
}