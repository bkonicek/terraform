terraform {
  required_version = "~> 1.3"

  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
  backend "remote" {
    organization = "bkonicek-personal"
    workspaces {
      name = "k8s-terraform"
    }
  }
}
