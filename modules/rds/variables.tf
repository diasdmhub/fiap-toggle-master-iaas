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