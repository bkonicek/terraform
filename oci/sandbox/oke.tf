# SecurityList and NSG rules adapted from: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm#example-flannel-cni-publick8sapi_privateworkers_publiclb

resource "oci_core_network_security_group" "k8s_apiserver" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "oke-apiserver"
}

resource "oci_core_network_security_group_security_rule" "ingress_apiserver_workers" {
  description               = "Allow worker node communication to k8s api"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction = "INGRESS"
  source    = oci_core_subnet.vcn_private_subnet.cidr_block
  protocol  = "6"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_apiserver_controlplane" {
  description               = "Allow worker node communication to k8s controlplane"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction = "INGRESS"
  source    = oci_core_subnet.vcn_private_subnet.cidr_block
  protocol  = "6"
  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_apiserver_home" {
  description               = "Allow apiserver ingress from HOME"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction = "INGRESS"
  source    = local.home_ip
  protocol  = "6"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_apiserver_path_discovery" {
  description               = "Allow inbound icmp discovery"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction = "INGRESS"
  source    = oci_core_subnet.vcn_private_subnet.cidr_block
  protocol  = "1"
  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "egress_oke" {
  description               = "Allow controlplane comms with OKE"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction        = "EGRESS"
  destination_type = "SERVICE_CIDR_BLOCK"
  destination      = "all-iad-services-in-oracle-services-network"
  protocol         = "6"
}

resource "oci_core_network_security_group_security_rule" "egress_services_icmp" {
  description               = "Allow controlplane path discovery with OKE"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction        = "EGRESS"
  destination_type = "SERVICE_CIDR_BLOCK"
  destination      = "all-iad-services-in-oracle-services-network"
  protocol         = "1"
  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "egress_workers_tcp" {
  description               = "Allow controlplane comms with worker nodes"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction   = "EGRESS"
  destination = oci_core_subnet.vcn_private_subnet.cidr_block
  protocol    = "6"
}

resource "oci_core_network_security_group_security_rule" "egress_workers_icmp" {
  description               = "Allow controlplane path disovery with workers"
  network_security_group_id = oci_core_network_security_group.k8s_apiserver.id

  direction   = "EGRESS"
  destination = oci_core_subnet.vcn_private_subnet.cidr_block
  protocol    = "1"
  icmp_options {
    type = 3
    code = 4
  }
}


resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.k8s_version
  name               = "oci-k8s"
  vcn_id             = module.vcn.vcn_id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.vcn_public_subnet.id
    nsg_ids              = [oci_core_network_security_group.k8s_apiserver.id]
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.vcn_public_subnet.id]
  }
}

resource "oci_core_network_security_group" "k8s_nodes" {
  compartment_id = var.compartment_id
  display_name   = "nsg-k8s-node"
  vcn_id         = module.vcn.vcn_id
}

resource "oci_core_network_security_group_security_rule" "ingress_worker_nodes" {
  description               = "Allow worker node communication"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction = "INGRESS"
  source    = oci_core_subnet.vcn_private_subnet.cidr_block
  protocol  = "all"
}

resource "oci_core_network_security_group_security_rule" "ingress_controlplane" {
  description               = "Allow control plane ingress"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction = "INGRESS"
  source    = "${split(":", oci_containerengine_cluster.k8s_cluster.endpoints[0].private_endpoint)[0]}/32"
  protocol  = "all"
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp" {
  description               = "Allow ICMP path discovery"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction = "INGRESS"
  source    = "0.0.0.0/0"
  protocol  = "1"
  icmp_options {
    code = 3
    type = 4
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_loadbalancer_tcp" {
  description               = "Allow load balancer ingress"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction = "INGRESS"
  source    = oci_core_subnet.vcn_public_subnet.cidr_block
  protocol  = "6"
  tcp_options {
    destination_port_range {
      min = 30000
      max = 32767
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_workernodes" {
  description               = "Allow comms between worker nodes"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction   = "EGRESS"
  destination = oci_core_subnet.vcn_private_subnet.cidr_block
  protocol    = "all"
}

resource "oci_core_network_security_group_security_rule" "egress_icmp" {
  description               = "Allow icmp out"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction   = "EGRESS"
  destination = "0.0.0.0/0"
  protocol    = "1"
  icmp_options {
    code = 3
    type = 4
  }
}

resource "oci_core_network_security_group_security_rule" "egress_workers_oke" {
  description               = "Allow workers comms with OKE"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction        = "EGRESS"
  destination_type = "SERVICE_CIDR_BLOCK"
  destination      = "all-iad-services-in-oracle-services-network"
  protocol         = "6"
}

resource "oci_core_network_security_group_security_rule" "egress_workers_kubeapi" {
  description               = "Allow workers comms to k8s api"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction   = "EGRESS"
  destination = "${split(":", oci_containerengine_cluster.k8s_cluster.endpoints[0].private_endpoint)[0]}/32"
  protocol    = "6"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_workers_controlplane" {
  description               = "Allow workers comms to k8s controlplane"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction   = "EGRESS"
  destination = "${split(":", oci_containerengine_cluster.k8s_cluster.endpoints[0].private_endpoint)[0]}/32"
  protocol    = "6"
  tcp_options {
    destination_port_range {
      min = 12250
      max = 12250
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress_internet" {
  description               = "Allow internet access"
  network_security_group_id = oci_core_network_security_group.k8s_nodes.id

  direction   = "EGRESS"
  destination = "0.0.0.0/0"
  protocol    = "6"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "arm_image" {
  compartment_id = var.compartment_id

  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.arm_node_shape
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
}

data "oci_core_images" "x86_image" {
  compartment_id = var.compartment_id

  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.x86_node_shape
  state                    = "AVAILABLE"
  sort_by                  = "TIMECREATED"
}

resource "oci_containerengine_node_pool" "k8s_arm_node_pool" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.k8s_version
  name               = "oci-k8s-node-pool-arm"
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    size = 2

    nsg_ids = [oci_core_network_security_group.k8s_nodes.id]
  }
  node_shape = var.arm_node_shape # always-free ARM
  node_shape_config {
    memory_in_gbs = 12
    ocpus         = 2
  }
  node_source_details {
    image_id    = data.oci_core_images.arm_image.images[0].id
    source_type = "image"
  }
  initial_node_labels {
    key   = "name"
    value = "oci-cluster"
  }
}
