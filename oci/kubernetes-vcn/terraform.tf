terraform {
  required_version = "~> 1.3"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 4.99"
    }
  }

  backend "remote" {
    organization = "bkonicek-personal"
    workspaces {
      name = "oci-terraform"
    }
  }
}
