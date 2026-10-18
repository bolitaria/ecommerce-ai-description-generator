# Oracle Cloud infrastructure (Terraform)

Provisions the network and compute for the ecommerce-ai stack in Oracle Cloud Always Free (`eu-madrid-1`).

## What it creates

| Resource | Purpose |
|---|---|
| `oci_core_vcn` | VCN `10.0.0.0/16` with DNS label `ecommerceai` |
| `oci_core_internet_gateway` | Outbound internet for the VCN |
| `oci_core_route_table` | `0.0.0.0/0` → internet gateway |
| `oci_core_security_list` | Ingress: 22 (SSH), 80 (HTTP), 443 (HTTPS) |
| `oci_core_subnet` | Public subnet `10.0.1.0/24` |
| `oci_core_instance` | `VM.Standard.A1.Flex` (ARM, 2 OCPU, 12 GB) |

## Prerequisites

- Oracle Cloud account (Always Free, home region `eu-madrid-1`)
- OCI CLI configured (`oci setup config`, API key uploaded to the console)
- Terraform >= 1.5.0
- SSH key pair (`~/.ssh/id_ed25519.pub`)

## How to get the OCIDs

From the Oracle Cloud console:

| Variable | Where |
|---|---|
| `tenancy_ocid` | Profile → Tenancy |
| `user_ocid` | Profile → My profile |
| `fingerprint` | Profile → API Keys (matches `~/.oci/config`) |
| `compartment_id` | Same as tenancy for root compartment |

## Usage

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your OCIDs
terraform init
terraform plan
terraform apply
```

## ARM capacity: the retry script

VM.Standard.A1.Flex is Always Free, which means Oracle gives it the lowest priority for capacity. In eu-madrid-1 it is common to receive:

```
Error: 500-InternalError, Out of host capacity.
```

This is not a configuration error. It means there is no free host with enough ARM capacity at that moment. The retry-apply.sh script retries terraform apply every 60 seconds until the instance is created:

```bash
nohup ./retry-apply.sh > /tmp/retry-apply.log 2>&1 &
```

The script treats as transient: Out of host capacity, EOF, connection reset, i/o timeout, TLS handshake timeout, 429, Service Unavailable. Any other error stops the loop and dumps the log.

To stop it:

```bash
pkill -f retry-apply.sh
```

## Outputs

```bash
terraform output
```

| Output | Description |
|---|---|
| `instance_public_ip` | Public IP of the ARM instance |
| `instance_ocid` | OCID of the instance |
| `ssh_command` | SSH command with the public IP |
| `vcn_id` | OCID of the VCN |

## Current status (2026-10-18)

- Network: provisioned in eu-madrid-1
- ARM instance: pending capacity (retry loop running)
- Cost: 0 EUR (Always Free)
