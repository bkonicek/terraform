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

# Manually deploy argocd one time with 
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/install.yaml

# Add the app-of-apps Application after installing Argo, ignore all changes as it will be
# managed by itself going forward
resource "kubernetes_manifest" "argo_base_app" {
  manifest = yamldecode(file("./manifests/application-argocd.yml"))
  lifecycle {
    ignore_changes = [all]
  }
}
