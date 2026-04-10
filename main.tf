module "vpc" {
  source = "./modules/vpc"
}

module "ecr" {
  source = "./modules/ecr"
}

module "eks" {
  source = "./modules/eks"
  vpc_id = module.vpc.id
  cluster_name = var.cluster_name
}