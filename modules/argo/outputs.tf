output "argocd_ip" {
  description = "IP do servico LoadBalancer do ArgoCD"
  value       = try(data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].ip, null)
}

output "argocd_url" {
  description = "URL para a API do ArgoCD"
  value       = try("http://${data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].hostname}", null)
}

output "namespace" {
  description = "Namespace para o ArgoCD"
  value       = helm_release.argocd.namespace
}

output "argocd_version" {
  description = "Deployed ArgoCD Helm chart version"
  value       = helm_release.argocd.version
}