# Instala o ArgoCD via Helm chart
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.1"
    }
  }
}

resource "helm_release" "argocd" {
  name             = "${var.name_prefix}-argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.chart_version != "" ? var.chart_version : null

  set = {
    name  = "server.service.type"
    value = var.service_type
  }
}