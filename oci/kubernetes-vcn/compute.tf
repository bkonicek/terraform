resource "oci_core_network_security_group" "bastion" {
  compartment_id = var.compartment_id
  display_name   = "bastion-ssh"
  vcn_id         = module.vcn.vcn_id
}

resource "oci_core_network_security_group_security_rule" "bastion_ssh" {
  network_security_group_id = oci_core_network_security_group.bastion.id
  description               = "Allow SSH from within private subnet"
  direction                 = "INGRESS"
  protocol                  = "6"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  source = oci_core_subnet.vcn_private_subnet.cidr_block
}

resource "oci_bastion_bastion" "bastion" {
  bastion_type                 = "STANDARD"
  compartment_id               = var.compartment_id
  client_cidr_block_allow_list = [local.home_ip]
  name                         = "ssh-bastion"
  target_subnet_id             = oci_core_subnet.vcn_private_subnet.id
}

data "oci_core_instance" "nfs" {
  instance_id = "ocid1.instance.oc1.iad.anuwcljtwrjyqsqc26rrfc65esfctojant2frgyacf7k3zu75iwibhtj2qga"
}
