#!/usr/bin/env bash
#
# verify-alerts.sh — wait for Prometheus to load ecommerce-ai rules.
# Fails if the rules are not loaded within the timeout (does NOT force a reload).
#
# Usage:
#   ./scripts/verify-alerts.sh [expected_count]
#
# Exit codes:
#   0  rules loaded
#   1  timeout or port-forward failed

set -euo pipefail

EXPECTED=${1:-8}
TIMEOUT=${TIMEOUT:-120}
INTERVAL=5
NAMESPACE_MONITORING="${NAMESPACE_MONITORING:-monitoring}"
PROM_SVC="${PROM_SVC:-kps-kube-prometheus-stack-prometheus}"

echo "Waiting for Prometheus to load ${EXPECTED} ecommerce-ai rules (timeout ${TIMEOUT}s)..."

# Start port-forward
pkill -f "port-forward.*9090" 2>/dev/null || true
sleep 1
kubectl port-forward -n "${NAMESPACE_MONITORING}" "svc/${PROM_SVC}" 9090:9090 >/dev/null 2>&1 &
PF_PID=$!
trap "kill ${PF_PID} 2>/dev/null || true" EXIT
sleep 3

DEADLINE=$(( $(date +%s) + TIMEOUT ))
while [[ "$(date +%s)" -lt "${DEADLINE}" ]]; do
  COUNT=$(curl -sf 'http://localhost:9090/api/v1/rules?type=alert' 2>/dev/null | \
    jq '[.data.groups[]? | select(.name | startswith("ecommerce-ai.")) | .rules | length] | add // 0' 2>/dev/null || echo 0)

  if [[ "${COUNT:-0}" -ge "${EXPECTED}" ]]; then
    echo "✅ Prometheus loaded ${COUNT} ecommerce-ai rules"
    echo
    echo "=== Rules ==="
    curl -sf 'http://localhost:9090/api/v1/rules?type=alert' | \
      jq -r '.data.groups[] | select(.name | startswith("ecommerce-ai.")) | .name as $g | .rules[] | "\($g) | \(.name) | \(.state)"'
    exit 0
  fi
  echo "  [$(date +%H:%M:%S)] ${COUNT:-0}/${EXPECTED} rules loaded, waiting..."
  sleep "${INTERVAL}"
done

echo "❌ Timeout: Prometheus did not load ${EXPECTED} ecommerce-ai rules in ${TIMEOUT}s"
echo
echo "Diagnose:"
echo "  kubectl get prometheusrule -n ecommerce-ai --show-labels"
echo "  kubectl get prometheus -n ${NAMESPACE_MONITORING} ${PROM_SVC} -o jsonpath='{.spec.ruleSelector}'"
echo "  kubectl logs -n ${NAMESPACE_MONITORING} deploy/kps-kube-prometheus-stack-operator --tail=50"
exit 1
