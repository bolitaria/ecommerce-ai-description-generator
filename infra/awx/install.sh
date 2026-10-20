#!/usr/bin/env bash
# Deploy AWX on a dedicated kind cluster. Idempotent.
# Usage:    ./infra/awx/install.sh
# Teardown: kind delete cluster --name awx
set -euo pipefail

CLUSTER_NAME=awx
OPERATOR_REF=2.19.1
NAMESPACE=awx
CR_NAME=awx
NODEPORT=30080
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1"; exit 1; }; }
require docker
require kind
require kubectl

echo "==> [1/5] Cluster ${CLUSTER_NAME}"
if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  echo "    exists, skipping"
else
  kind create cluster --name "${CLUSTER_NAME}" --config "${HERE}/kind-config.yaml"
fi
kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

echo "==> [2/5] Namespace ${NAMESPACE}"
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

echo "==> [3/5] AWX Operator ref=${OPERATOR_REF}"
if kubectl -n "${NAMESPACE}" get deploy awx-operator-controller-manager >/dev/null 2>&1; then
  echo "    exists, skipping"
else
  kubectl apply -k "${HERE}"
  kubectl -n "${NAMESPACE}" wait --for=condition=Available \
    deployment/awx-operator-controller-manager --timeout=180s
fi

echo "==> [4/5] AWX CR"
kubectl apply -f "${HERE}/awx.yaml"
echo "    waiting for AWX pods (up to 10 min)..."
for i in $(seq 1 60); do
  ready=$(kubectl -n "${NAMESPACE}" get pods \
    -l "app.kubernetes.io/name=awx,app.kubernetes.io/instance=${CR_NAME}" \
    -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' \
    2>/dev/null | grep -c True || true)
  [ "${ready}" -ge 3 ] && { echo "    AWX ready"; break; }
  sleep 10; echo "    ... ${i}/60"
done

echo "==> [5/5] Admin password"
PASS=$(kubectl -n "${NAMESPACE}" get secret "${CR_NAME}-admin-password" \
  -o jsonpath='{.data.password}' | base64 --decode)

printf '\nAWX up.\n  URL:      http://localhost:%s\n  User:     admin\n  Password: %s\n\n' \
  "${NODEPORT}" "${PASS}"
printf 'Next (UI): Project, Inventory, Machine Credential, Job Template.\n'
printf 'Teardown:  kind delete cluster --name %s\n' "${CLUSTER_NAME}"
