resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  version   = "7.3.1"
  
  wait = "false"
  values = [
    file("${path.module}/grafana-config/values.yaml")
  ]
}
