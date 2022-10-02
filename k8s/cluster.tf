provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "context-c6lpwtrw5ka"
}

provider "oci" {
  region = var.region
}
