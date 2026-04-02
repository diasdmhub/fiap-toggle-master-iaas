variable "vpc_name" {
  description = "Name prefix for the VPC and related resources - matches TAG_PREFIX"
  type        = string
  default     = "env-vpc"
}

variable "subnet_prefix" {
  description = "First two octets of the VPC CIDR - matches SUB_PREFIX"
  type        = string
  default     = "10.12"
}

variable "public_subnet_nums" {
  description = "Third octet values for public subnets - one per AZ, matches PUBLIC_SUBNET_NUMS"
  type        = list(number)
  default     = [11, 21, 31, 41, 51, 61]
}

variable "private_subnet_nums" {
  description = "Third octet values for private subnets - one per AZ, matches PRIVATE_SUBNET_NUMS"
  type        = list(number)
  default     = [12, 22, 32, 42, 52, 62]
}