output "argo_cd_cluster_ip" {
  description = "IP do servico LoadBalancer do ArgoCD"
  value       = helm_release.argocd.status.load_balancer_ingress[*].ip
}

output "argo_cd_external_url" {
  description = "URL para a API do ArgoCD"
  value       = "http://${helm_release.argocd.status.load_balancer_ingress[*].hostname}"
}

output "namespace" {
  description = "Namespace para o ArgoCD"
  value       = helm_release.argocd.namespace
}

output "argocd_version" {
  description = "Deployed ArgoCD Helm chart version"
  value       = helm_release.argocd.version
}