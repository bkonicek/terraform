# Cluster-autoscaler IAM
resource "oci_identity_dynamic_group" "cluster_autoscaler" {
  compartment_id = var.compartment_id
  description    = "Dynamic group for OKE Cluster autoscaler"
  matching_rule  = "All {instance.compartment.id = '${var.compartment_id}', tag.Oracle-Tags.CreatedBy.value='oke'}"
  name           = "oke-cluster-autoscaler-dyn-group"
}

resource "oci_identity_policy" "autoscaler_manage_nodepools" {
  compartment_id = var.compartment_id
  description    = "Allow worker nodes to manage node pools for cluster autoscaler"
  name           = "worker-node-cluster-autoscaler-node-pool"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler.name} to manage cluster-node-pools in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler.name} to manage instance-family in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler.name} to use subnets in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler.name} to read virtual-network-family in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler.name} to use vnics in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.cluster_autoscaler.name} to inspect compartments in tenancy",
  ]
}
