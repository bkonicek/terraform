data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

resource "oci_objectstorage_bucket" "backups" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "benkonicek-backups-${var.region}"
  versioning     = "Enabled"
}

resource "oci_objectstorage_object_lifecycle_policy" "backups_lifecycle" {
  depends_on = [oci_identity_policy.objectstorage_lifecycle_service]

  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = oci_objectstorage_bucket.backups.name

  rules {
    name        = "expire-previous-versions"
    action      = "DELETE"
    target      = "previous-object-versions"
    time_amount = 30
    time_unit   = "DAYS"
    is_enabled  = true
  }
}
