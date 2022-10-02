data "terraform_remote_state" "oci" {
  backend = "local"

  config = {
    path = "../oci/kubernetes-vcn/terraform.tfstate"
  }
}
