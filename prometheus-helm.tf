
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.5.0"
  namespace  = "monitoring"
  
  values = [
    file("${path.module}/prometheus-config/values.yaml")
  ]
}
