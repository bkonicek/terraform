provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "context-c6lpwtrw5ka"
  }
}

resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress-controller"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.2.0"

  set {
    name  = "controller.service.annotations.oci\\.oraclecloud\\.com/load-balancer-type"
    value = "nlb"
  }
}
