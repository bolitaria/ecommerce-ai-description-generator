# Runbook — ecommerce-ai platform

Operational procedures for the ecommerce-ai platform. Every alert defined in
`helm/ecommerce-ai/templates/prometheusrule.yaml` links to a section here.

---

## Table of contents

- [When an alert fires](#when-an-alert-fires)
- [Alerts](#alerts)
  - [HighErrorRate](#higherrorrate)
  - [HighLatencyP95](#highlatencyp95)
  - [TrafficDrop](#trafficdrop)
  - [AIProviderHighErrorRate](#aiproviderhigherrorrate)
  - [AIProviderFallbackStorm](#aiproviderfallbackstorm)
  - [PodCrashLooping](#podcrashlooping)
  - [PodNotReady](#podnotready)
  - [HPAAtMaxReplicas](#hpaatmaxreplicas)
- [Rollback](#rollback)
- [Rotate the internal API token](#rotate-the-internal-api-token)
- [Scale a service manually](#scale-a-service-manually)
- [Emergency procedures](#emergency-procedures)
- [Known gaps](#known-gaps)

---

## When an alert fires {#when-an-alert-fires}

1. **Acknowledge** the alert in Alertmanager / Slack / PagerDuty.
2. **Open this runbook** at the matching section (link in every alert).
3. **Check Grafana**: "Ecommerce-AI Platform" dashboard → find the affected service.
4. **Check recent changes**: `git log --oneline -20 origin/main`. Did a deployment just happen? If yes, consider rollback first.
5. **If impact is severe**, roll back first and investigate after. A rollback is cheap; a prolonged outage is not.

---

## Alerts

### HighErrorRate {#higherrorrate}

**Severity:** critical
**Meaning:** More than 5% of HTTP responses are 5xx for 5 minutes on a service.

**Diagnosis:**

```bash
kubectl logs -n ecommerce-ai -l app.kubernetes.io/name=<service> --tail=200 | grep -i error
kubectl get pods -n ecommerce-ai -l app.kubernetes.io/name=<service>
```

**Common causes:**

- Recent deployment with a bug → rollback (see [Rollback](#rollback)).
- Database unreachable → check `pod/postgres-0` and `DATABASE_URL` in the Secret.
- Downstream service down (core-api → ai-service) → check the target service.

---

### HighLatencyP95 {#highlatencyp95}

**Severity:** warning
**Meaning:** p95 latency above 1s for 5 minutes on a service.

**Diagnosis:**

1. Grafana → "HTTP latency p95" panel → identify the affected route.
2. If `ai-service`: check `ai_provider_request_duration_seconds` per provider. A slow provider may be causing the delay.
3. Check `kubectl top pod -n ecommerce-ai` for CPU throttling.

**Common causes:**

- LLM provider slow → check `ai_provider_fallbacks_total`. If the fallback is not kicking in, the primary is degraded.
- Postgres slow query → check `pg_stat_activity`.
- CPU throttling → raise `resources.limits.cpu` in the affected service.

---

### TrafficDrop {#trafficdrop}

**Severity:** warning
**Meaning:** A service receives zero requests for 10 minutes.

**Diagnosis:**

```bash
kubectl get endpoints -n ecommerce-ai <service>
kubectl describe ingress -n ecommerce-ai ecommerce-ai
```

**Common causes:**

- Ingress misconfigured → check `kubectl describe ingress`.
- NetworkPolicy blocking → check `kubectl describe networkpolicy -n ecommerce-ai`.
- Service selector mismatch → pods not selected by the Service.

---

### AIProviderHighErrorRate {#aiproviderhigherrorrate}

**Severity:** warning
**Meaning:** A single AI provider is failing more than 10% of requests for 5 minutes.

**Diagnosis:**

```bash
kubectl logs -n ecommerce-ai deployment/ecommerce-ai-ai-service --tail=200 | grep -i "provider failed"
```

**Common causes:**

- Provider API key invalid or expired → check `ecommerce-ai-secrets` Secret.
- Provider rate-limited (HTTP 429) → the fallback handles it, but the primary is degraded.
- Provider outage → check the provider status page.

**Action:** the fallback chain handles this transparently. Investigate only if it persists > 30 minutes.

---

### AIProviderFallbackStorm {#aiproviderfallbackstorm}

**Severity:** warning
**Meaning:** Fallbacks happen more than once per second for 5 minutes.

**Diagnosis:**

```bash
kubectl logs -n ecommerce-ai deployment/ecommerce-ai-ai-service --tail=500 | grep "AI provider failed"
```

**Common causes:** same as [AIProviderHighErrorRate](#aiproviderhigherrorrate) but sustained.

**Action:** if the primary provider is degraded for a long period, disable it temporarily by emptying its API key in `values-dev.yaml` / `values-prod.yaml`.

---

### PodCrashLooping {#podcrashlooping}

**Severity:** critical
**Meaning:** A pod has restarted more than 3 times in 15 minutes.

**Diagnosis:**

```bash
kubectl describe pod -n ecommerce-ai <pod> | tail -30
kubectl logs -n ecommerce-ai <pod> --previous --tail=100
```

**Common causes:**

- Config error (bad `DATABASE_URL`, missing secret).
- Migration failure (core-api runs migrations on startup).
- OOMKilled → check `kubectl describe pod` for `OOMKilled` and raise memory limit.

**If it's a startup dependency:** e.g. core-api fails because postgres isn't ready yet → `kubectl rollout restart deployment/ecommerce-ai-core-api` once postgres is up.

---

### PodNotReady {#podnotready}

**Severity:** warning
**Meaning:** A pod has been not-ready for 5 minutes (readiness probe failing).

**Diagnosis:**

```bash
kubectl describe pod -n ecommerce-ai <pod> | grep -A5 "Readiness"
```

**Common causes:**

- Readiness endpoint returns 5xx (application not initialized).
- Probe path/timing wrong → check the `readinessProbe` in the chart values.
- Network issue between kubelet and pod.

---

### HPAAtMaxReplicas {#hpaatmaxreplicas}

**Severity:** warning
**Meaning:** The HPA has been at max replicas for 15 minutes.

**Diagnosis:**

```bash
kubectl get hpa -n ecommerce-ai
kubectl describe hpa -n ecommerce-ai ecommerce-ai-ai-service
```

**Action:**

- If sustained, raise `autoscaling.maxReplicas` in `values-prod.yaml`.
- Or investigate why the load is so high (traffic spike, bug, infinite loop).

---

## Rollback {#rollback}

**Preferred (GitOps):**

```bash
git revert <bad-commit-sha>
git push origin main
# Argo CD reconciles back to the previous state automatically.
```

**Emergency (Helm):**

```bash
helm history ecommerce-ai -n ecommerce-ai
helm rollback ecommerce-ai <previous-revision> -n ecommerce-ai
```

**Single service (kubectl):**

```bash
kubectl rollout undo deployment/ecommerce-ai-core-api -n ecommerce-ai
```

---

## Rotate the internal API token {#rotate-the-internal-api-token}

```bash
# 1. Generate a new token
NEW_TOKEN=$(openssl rand -hex 32)

# 2. Update the Secret (Reloader triggers a rolling restart)
kubectl create secret generic ecommerce-ai-secrets \
  --from-literal=INTERNAL_API_TOKEN="$NEW_TOKEN" \
  --dry-run=client -o yaml | kubectl apply -f - -n ecommerce-ai

# 3. Verify pods restarted
kubectl rollout status deployment/ecommerce-ai-ai-service -n ecommerce-ai
kubectl rollout status deployment/ecommerce-ai-core-api -n ecommerce-ai
```

---

## Scale a service manually {#scale-a-service-manually}

```bash
# If HPA is enabled, manual scaling will be reverted. Disable HPA first:
kubectl patch hpa ecommerce-ai-ai-service -n ecommerce-ai \
  --type=json -p='[{"op":"remove","path":"/spec/metrics"}]'

# Then scale
kubectl scale deployment ecommerce-ai-ai-service -n ecommerce-ai --replicas=5
```

---

## Emergency procedures {#emergency-procedures}

### Full platform outage

1. Confirm: `curl -f https://<your-domain>/health` → fails?
2. Check cluster: `kubectl get nodes`, `kubectl get pods -A`.
3. If cluster is up but app is down → [Rollback](#rollback).
4. If cluster is down → escalate to infra / cloud provider.
5. Communicate: status page update, incident channel.

### Database is down

Postgres runs as a StatefulSet in dev (`postgres-0`). In production, use a managed database.

```bash
kubectl get pod -n ecommerce-ai postgres-0
kubectl logs -n ecommerce-ai postgres-0 --tail=100

# If it's transient, restarting usually works
kubectl delete pod -n ecommerce-ai postgres-0

# If persistent, check the PVC
kubectl get pvc -n ecommerce-ai
```

---

## Known gaps {#known-gaps}

- **No backups yet.** If the Postgres PVC is lost, all data is lost. See the "Backups" phase in the roadmap.
- **No real Alertmanager receiver.** Currently points to `httpbin.org` for validation. In production, replace with Slack/PagerDuty/email.
- **No multi-region DR.** The platform runs in a single cluster.
---

## Alerts not appearing in Prometheus

If you just deployed a new `PrometheusRule` and Prometheus doesn't see it:

1. **Wait 30 seconds.** The Prometheus Operator reconciles asynchronously.
2. Check the rule exists: `kubectl get prometheusrule -n ecommerce-ai`
3. Check the selector: `kubectl get prometheus -n monitoring kps-kube-prometheus-stack-prometheus -o jsonpath='{.spec.ruleSelector}'` should return `{}`.
4. Run the verification script: `./scripts/verify-alerts.sh 8`
5. If it times out after 2 minutes, check the Operator logs:
   `kubectl logs -n monitoring deploy/kps-kube-prometheus-stack-operator --tail=50`
6. **Do NOT force reloads with `kubectl label --overwrite`.** If the Operator isn't reconciling, there's a root cause to investigate (operator down, RBAC, selector misconfigured). Forcing a reload hides the problem.

In production with Argo CD, the Operator reconciles continuously. No intervention is needed.

---

## Additional alerts (alerting-hardening)

These alerts complement the original 8 with infrastructure coverage and
root-cause-symptom inhibition.

### AIProviderTotalOutage {#aiprovidertotaloutage}

**Severity:** critical
**Meaning:** The AI fallback chain is receiving requests but all providers
are failing. Every user-facing `/api/v1/generate` call returns 500.

**Diagnosis:**

```bash
kubectl logs -n ecommerce-ai deploy/ecommerce-ai-ai-service --tail=200 | grep -i "provider failed"
Common causes:

All API keys invalid or expired.

Network egress blocked (firewall, DNS).

Provider outages across the board (rare but happens).

Action: check ecommerce-ai-secrets Secret, verify outbound connectivity
from the pod, check each provider's status page.

---

### KubeDeploymentReplicasMismatch {#kubedeploymentreplicasmismatch}

**Severity:** critical | **Trigger:** Deployment with fewer available replicas than desired for 10m.

**Why this replaces PodNotReady:** PodNotReady fires on rolling updates. This only fires when the Deployment cannot converge.

**Diagnosis:** `kubectl get deploy -n ecommerce-ai && kubectl describe deploy -n ecommerce-ai <deployment>`

**Causes:** ImagePullBackOff, crash loop, insufficient resources, PDB blocking eviction.

---

### PVCUsageHigh {#pvcusagehigh}

**Severity:** warning | **Trigger:** PVC above 80% capacity for 10m.

**Diagnosis:** `kubectl get pvc -n ecommerce-ai && kubectl exec -n ecommerce-ai postgres-0 -- df -h /var/lib/postgresql/data`

**Action:** resize PVC or clean up data.

---

### KubeNodeNotReady {#kubenodenotready}

**Severity:** critical | **Trigger:** node NotReady for 5m.

**Diagnosis:** `kubectl get nodes && kubectl describe node <node> | tail -20`

**Action:** check kubelet logs, disk/memory pressure, network.

---

### CertificateExpiringSoon {#certificateexpiringsoon}

**Severity:** warning | **Trigger:** cert-manager cert expires in <14 days.

**Diagnosis:** `kubectl get certificate -A`

**Action:** verify cert-manager renewal; check ACME challenge. Never disable.

---

## Inhibited alerts

When the root cause fires, symptoms are silenced (one page per incident):

| Root cause | Inhibits |
|---|---|
| PodCrashLooping | HighErrorRate, HighLatencyP95_* (same app) |
| KubeDeploymentReplicasMismatch | HighErrorRate, HighLatencyP95_* (same app) |
| KubeNodeNotReady | PodCrashLooping, KubeDeploymentReplicasMismatch (same node) |
| AIProviderTotalOutage | AIProviderHighErrorRate, AIProviderFallbackStorm |
