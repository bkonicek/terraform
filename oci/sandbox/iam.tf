resource "oci_identity_dynamic_group" "oke_nodes" {
  compartment_id = var.compartment_id
  description    = "Dynamic group for all OKE Cluster nodes"
  matching_rule  = "All {instance.compartment.id = '${var.compartment_id}', tag.Oracle-Tags.CreatedBy.value='oke'}"
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
