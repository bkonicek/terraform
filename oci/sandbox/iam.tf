# Custom defined tag used to mark OKE worker node instances so the dynamic group below can
# match them. Applied to the node pool's node_config_details in oke.tf. A custom tag is needed
# because dynamic group matching rules only support defined tags, not freeform tags.
resource "oci_identity_tag_namespace" "oke" {
  compartment_id = var.compartment_id
  name           = "oke"
  description    = "Tags for identifying OKE-managed resources"
}

resource "oci_identity_tag" "oke_node" {
  tag_namespace_id = oci_identity_tag_namespace.oke.id
  name             = "node"
  description      = "Marks an instance as an OKE worker node, for dynamic-group matching"
}

resource "oci_identity_dynamic_group" "oke_nodes" {
  compartment_id = var.compartment_id
  description    = "Dynamic group for all OKE Cluster nodes"
  matching_rule  = "All {instance.compartment.id = '${var.compartment_id}', tag.${oci_identity_tag_namespace.oke.name}.${oci_identity_tag.oke_node.name}.value='true'}"
  name           = "oke-dyn-group-all"
}

# Cluster-autoscaler IAM
resource "oci_identity_policy" "autoscaler_manage_nodepools" {
  compartment_id = var.compartment_id
  description    = "Allow worker nodes to manage node pools for cluster autoscaler"
  name           = "worker-node-cluster-autoscaler-node-pool"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage cluster-node-pools in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage instance-family in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to use subnets in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to read virtual-network-family in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to use vnics in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to inspect compartments in tenancy",
  ]
}

# Metrics for Grafana
resource "oci_identity_policy" "grafana_policy" {
  compartment_id = var.compartment_id
  description    = "Allow worker nodes to read infrastructure metrics"
  name           = "grafana_policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to read metrics in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to read compartments in tenancy",
  ]
}

# Required for Object Storage to execute lifecycle policies (e.g. deleting old object
# versions) on our behalf: https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usinglifecyclepolicies.htm
resource "oci_identity_policy" "objectstorage_lifecycle_service" {
  compartment_id = var.compartment_id
  description    = "Allow the Object Storage service to execute lifecycle policies on buckets"
  name           = "objectstorage-lifecycle-service-access"
  statements = [
    "Allow service objectstorage-${var.region} to manage object-family in compartment id ${var.compartment_id}",
  ]
}

# Backups bucket access
resource "oci_identity_policy" "oke_backups_bucket_access" {
  compartment_id = var.compartment_id
  description    = "Allow worker nodes to read and write objects in the backups bucket"
  name           = "oke-backups-bucket-access"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to read buckets in compartment id ${var.compartment_id} where target.bucket.name='${oci_objectstorage_bucket.backups.name}'",
    # "manage" (not "use") is required: OBJECT_CREATE (writing an object name for the first
    # time, e.g. the backup CronJob's first run) is only granted at the manage tier -- "use"
    # only covers OBJECT_OVERWRITE. See:
    # https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/objectstoragepolicyreference.htm
    "Allow dynamic-group ${oci_identity_dynamic_group.oke_nodes.name} to manage objects in compartment id ${var.compartment_id} where target.bucket.name='${oci_objectstorage_bucket.backups.name}'",
  ]
}
