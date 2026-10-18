# Oracle Cloud deployment

End-to-end deployment of the ecommerce-ai stack on Oracle Cloud Always Free.

## Status

| Step | Status | Date |
|---|---|---|
| 1. Terraform: network + compute | Network done, ARM pending capacity | 2026-10-18 |
| 2. Ansible: hardening + k3s | Pending | - |
| 3. Multi-arch images in CI | Pending | - |
| 4. Helm install on k3s | Pending | - |
| 5. cert-manager + Let's Encrypt | Pending | - |
| 6. DNS (nip.io) + HTTPS | Pending | - |
| 7. Argo CD (GitOps) | Pending | - |

## Architecture

```
[User] -> https://ecommerce-ai.<IP>.nip.io
             |
       [Ingress NGINX] (TLS: Let's Encrypt)
             |
       +-----+------+----------+----------+
       |            |          |          |
  [frontend]  [core-api]  [ai-service]  [monitoring]
                  |            |
              [Postgres]   [providers]
```

## Step 1: Terraform

See [infra/terraform/README.md](../infra/terraform/README.md).

Pending: ARM instance (VM.Standard.A1.Flex) waiting for Oracle capacity. The retry loop runs every 60s. When successful, `terraform output` will print the public IP.

## Steps 2-7

_TODO: Ansible (hardening + k3s), multi-arch CI, Helm install, TLS, DNS, Argo CD._
