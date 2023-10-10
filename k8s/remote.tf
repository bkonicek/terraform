data "terraform_remote_state" "oci" {
  backend = "remote"

  config = {
    organization = "bkonicek-personal"
    workspaces = {
      name = "oci-terraform"
    }
  }
}
