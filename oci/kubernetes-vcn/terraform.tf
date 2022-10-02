terraform {
  required_version = "~> 1.3"
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
