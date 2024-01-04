provider "oci" {
  region       = var.region
  tenancy_ocid = var.compartment_id
}
