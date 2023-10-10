provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "oci"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  name       = "argocd"
  version    = "5.46.7"
  namespace  = kubernetes_namespace.argocd.id
}

resource "kubernetes_manifest" "argo_base_app" {
  manifest = yamldecode(file("./manifests/application-argocd.yml"))

  depends_on = [helm_release.argocd]
}
