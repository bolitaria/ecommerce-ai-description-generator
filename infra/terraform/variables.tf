variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "API key fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key"
  type        = string
  default     = "~/.oci/oci_api_key.pem"
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "eu-madrid-1"
}

variable "compartment_id" {
  description = "OCID of the compartment (tenancy OCID for root)"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "instance_ocpus" {
  description = "OCPUs for the ARM instance (Always Free max: 2)"
  type        = number
  default     = 2
}

variable "instance_memory_gbs" {
  description = "Memory in GB for the ARM instance (Always Free max: 12)"
  type        = number
  default     = 12
}
