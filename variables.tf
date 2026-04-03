variable "name_prefix" {
  description = "Prefixo do nome dos recursos"
  type        = string
  default     = "fiap-toggle"
}

variable "subnet_prefix" {
  description = "Os 2 primeiros octetos do CIDR da VPC"
  type        = string
  default     = "10.12"
}

variable "public_subnet_nums" {
  description = "O terceiro octeto para subnets públicas - um por AZ"
  type        = list(number)
  default     = [11, 21, 31, 41, 51, 61]
}

variable "private_subnet_nums" {
  description = "O terceiro octeto para subnets privadas - um por AZ"
  type        = list(number)
  default     = [12, 22, 32, 42, 52, 62]
}

variable "service_list" {
  description = "Lista de nomes de serviços para os repositórios ECR"
  type        = set(string)
  default     = [
    "auth",
    "flag",
    "targeting",
    "evaluation",
    "analytics",
  ]
}

variable "db_name" {
  description = "Nome do banco de dados inicial no RDS"
  type        = string
  default     = "toggle_db"
}

variable "db_username" {
  description = "Usuário master do PostgreSQL"
  type        = string
  default     = "toggle"
}

variable "db_password" {
  description = "Senha do usuário master (use variável de ambiente para produção)"
  type        = string
  default     = "toggle_dbmaster"
  sensitive   = true
}