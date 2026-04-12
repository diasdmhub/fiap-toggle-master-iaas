# VPC (principal)
module "vpc" {
  source = "./modules/vpc"

  name_prefix         = var.name_prefix
  subnet_prefix       = var.subnet_prefix
  public_subnet_nums  = var.public_subnet_nums
  private_subnet_nums = var.private_subnet_nums
}

# Módulos que dependem da VPC
module "eks" {
  source = "./modules/eks"

  name_prefix        = var.name_prefix
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  depends_on = [module.vpc]
}

module "rds" {
  source = "./modules/rds"

  name_prefix        = var.name_prefix
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.vpc]
}

module "cache" {
  source = "./modules/cache"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.vpc]
}

# Módulos independentes
module "sqs" {
  source = "./modules/sqs"

  name_prefix = var.name_prefix
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix  = var.name_prefix
}

module "dynamo" {
  source = "./modules/dynamo"

  name_prefix = var.name_prefix
}

module "oidc" {
  source = "./modules/oidc"

  name_prefix = var.name_prefix
  git_org     = var.git_org
  git_repo    = var.git_repo
}