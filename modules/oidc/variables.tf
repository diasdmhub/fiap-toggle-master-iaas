variable "name_prefix" {
  description = "Prefixo do nome dos recursos"
  type        = string
}

variable "git_org" {
  description = "git account"
  type        = string
}

variable "git_repo" {
  description = "git repository"
  type        = string
}

variable "git_branch" {
  description = "git branch"
  type        = string
  default     = "main"
}