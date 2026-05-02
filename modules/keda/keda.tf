resource "kubernetes_namespace" "keda" {
  metadata {
    name = "keda"
  }
}

resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = var.chart_version != "" ? var.chart_version : null
  namespace  = kubernetes_namespace.keda.metadata[0].name

  set {
    name  = "watchNamespace"
    value = ""  # vazio = monitora todos os namespaces
  }

  depends_on = [kubernetes_namespace.keda]
}