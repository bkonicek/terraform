variable "region" {
  type    = string
  default = "us-ashburn-1"
}

variable "compartment_id" {
  type    = string
  default = "ocid1.tenancy.oc1..aaaaaaaagrijaszt6hht7kcyfsjbgax6d4kigppo234qrs2f6ftp5k7nlocq"
}

variable "home_ip" {
  type    = string
  default = "107.15.177.214/32"
}

variable "k8s_version" {
  type    = string
  default = "v1.23.4"
}

variable "arm_node_shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "x86_node_shape" {
  type    = string
  default = "VM.Standard.E2.1.Micro"
}
