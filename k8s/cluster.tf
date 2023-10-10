provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "oci"
}

provider "oci" {
  region = var.region
}
