variable "name_prefix" {
  description = "Prefixo para nomear os recursos"
  type        = string
}

variable "namespace" {
  description = "Namespace Kubernetes onde a service account será criada"
  type        = string
  default     = "toggle"
}

variable "oidc_provider_arn" {
  description = "ARN do OIDC provider do cluster EKS (para IRSA)"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL do OIDC provider do cluster EKS (sem o prefixo https://)"
  type        = string
}

variable "extra_policy_json" {
  description = "Conteúdo JSON da política extra (toggle-policy.json com account_id já substituído)"
  type        = string
}