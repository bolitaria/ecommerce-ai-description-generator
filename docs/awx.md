# AWX on kind

Self-hosted AWX (open-source Ansible Automation Platform) running on a
dedicated `kind` cluster, used to demonstrate and operate the Ansible
roles in `infra/ansible/`.

## What AWX adds over `ansible-playbook`

Ansible is the engine. AWX is the operational layer:

| Ansible CLI | AWX |
|---|---|
| `ansible-playbook -i inventory.yml playbook.yml` | Web UI + REST API |
| SSH keys on the operator's laptop | Encrypted Credentials with RBAC |
| No audit trail | Every job logged: who, when, what, output, exit code |
| Manual `cron` | Schedules |
| No notifications | Webhooks to Slack / email |
| One engineer | Multi-tenant (Organizations, Teams) |

## Architecture

```
kind cluster "awx" (1 control-plane node)
└── namespace awx
    ├── awx-operator-controller-manager   (Deployment, 2/2)
    ├── awx-postgres-15-0                  (StatefulSet, 1/1)
    ├── awx-web-*                          (Deployment, 3/3)
    ├── awx-task-*                         (Deployment, 4/4)
    └── awx-migration-*                    (Job, Completed)
```

AWX is exposed via NodePort `30080`, mapped to host port `30080` by the
kind `extraPortMappings` in `kind-config.yaml`.

## Prerequisites

- Docker (tested with 29.x on WSL2)
- `kind` >= 0.20
- `kubectl` >= 1.28
- ~6 GB RAM and ~10 GB disk free for the kind cluster + AWX

## Install

```bash
./infra/awx/install.sh
```

The script is idempotent: safe to re-run. It creates the kind cluster,
installs the AWX Operator, applies the AWX custom resource, waits for
all pods to be Ready, and prints the admin password.

Manual equivalent:

```bash
kind create cluster --name awx --config infra/awx/kind-config.yaml
kubectl config use-context kind-awx
kubectl create namespace awx
kubectl apply -k infra/awx/
kubectl apply -f infra/awx/awx.yaml
```

Access: <http://localhost:30080> — user `admin`, password from:

```bash
kubectl -n awx get secret awx-admin-password -o jsonpath='{.data.password}' | base64 --decode
```

## AWX objects used

| Object | Name | Purpose |
|---|---|---|
| Project | `ecommerce-ai-infra` | Git clone of this repo (branch `feat/awx-on-kind` during validation, `main` after merge) |
| Inventory | `localhost` | Single host `localhost` with `ansible_connection: local` — no SSH |
| Job Template | `AWX smoke test` | Runs `infra/ansible/tests/awx-smoke.yml` against the inventory |

## Known issues and fixes

### 1. `gcr.io/kubebuilder/kube-rbac-proxy` no longer exists

awx-operator 2.19.1 references `gcr.io/kubebuilder/kube-rbac-proxy:v0.15.0`.
Google Container Registry was discontinued, so the sidecar cannot pull,
the operator stays `1/2 ImagePullBackOff`, and the deployment never
becomes Available.

Fix: `kustomization.yaml` wraps the upstream operator and overrides the
image to `quay.io/brancz/kube-rbac-proxy:v0.15.0`. The local
`kustomization.yaml` is applied instead of the remote one.

### 2. `awx-projects-claim` stuck Pending

AWX defaults the projects PVC to `ReadWriteMany`. kind's `local-path`
provisioner only supports `ReadWriteOnce`. The PVC never binds and
`awx-web`/`awx-task` stay Pending.

Fix: `projects_storage_access_mode: ReadWriteOnce` in `awx.yaml`. On a
single-node cluster this is functionally equivalent to RWX.

## Lessons learned

- Pin the operator version (`ref=2.19.1`, not `latest`).
- Pin image tags in the kustomization.
- On kind, `ReadWriteOnce` is enough for a single node.
- `ImagePullBackOff` on the sidecar with `awx-manager Running` means the
  operator works, the sidecar does not.

## Demo (3 minutes, for a portfolio walkthrough)

1. Open <http://localhost:30080>, log in as `admin`.
2. Resources → Templates → **AWX smoke test**.
3. Click **Launch**.
4. Expected output ends with:

```
localhost : ok=2 changed=0 failed=0
```

5. Open the Job detail: template config, launch user, git revision,
   duration, full stdout.

This proves git pull, playbook parse, inventory match, execution, output
capture and audit log — end to end.

## Teardown

```bash
kind delete cluster --name awx
```

Deletes the cluster, all PVCs, the AWX database, and the git clone. The
`infra/awx/` files in the repo are not affected.
