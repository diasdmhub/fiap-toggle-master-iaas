# Provider region is taken from AWS CLI configuration
provider "aws" {}

# Fetch all available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpc_cidr = "${var.subnet_prefix}.0.0/16"

  # List of AZs
  azs = data.aws_availability_zones.available.names

  # Public subnet CIDRs (non-overlapping third octet)
  public_subnet_cidrs = [
    for i in range(length(local.azs)) :
    "${var.subnet_prefix}.${var.public_subnet_nums[i]}.0/24"
  ]

  # Private subnet CIDRs
  private_subnet_cidrs = [
    for i in range(length(local.azs)) :
    "${var.subnet_prefix}.${var.private_subnet_nums[i]}.0/24"
  ]
}

# VPC creation + DNS attributes
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Public subnets (one per AZ) with auto-assign public IP
resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-subnet-pub-${var.public_subnet_nums[count.index]}"
    Tier = "public"
    AZ   = local.azs[count.index]
  }
}

# Private subnets (one per AZ) with no auto-assign public IP
resource "aws_subnet" "private" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.private_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.vpc_name}-subnet-priv-${var.private_subnet_nums[count.index]}"
    Tier = "private"
    AZ   = local.azs[count.index]
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Tags the default VPC route table
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name = "${var.vpc_name}-auto-main-rtb"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-public-rtb"
  }
}

# Private route table (no routes added)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-private-rtb"
  }
}

# Default route (0.0.0.0/0) via IGW on the public route table
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}