terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 4.85"
    }
  }

  backend "remote" {
    organization = "bkonicek-personal"
    workspaces {
      name = "oci-terraform"
    }
  }
}
