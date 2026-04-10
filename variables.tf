variable "name_prefix" {
  description = "Prefixo do nome dos recursos"
  type        = string
  default     = "fiap-toggle"
}

variable "region" {
  description = "Regiao da AWS"
  type        = string
  default     = "us-east-1"
}