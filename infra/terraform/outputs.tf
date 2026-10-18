output "instance_public_ip" {
  description = "Public IP of the k3s instance"
  value       = oci_core_instance.k3s.public_ip
}

output "instance_ocid" {
  description = "OCID of the k3s instance"
  value       = oci_core_instance.k3s.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${oci_core_instance.k3s.public_ip}"
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.main.id
}
