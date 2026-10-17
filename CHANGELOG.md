# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `PrometheusRule` with 14 SLO-based alerts:
  - HTTP: `HighErrorRate`, `HighLatencyP95_*` (per-service), relative `TrafficDrop`
  - AI: `AIProviderTotalOutage`, `AIProviderHighErrorRate`, `AIProviderFallbackStorm`
  - K8s: `KubeDeploymentReplicasMismatch`, `PodCrashLooping`, `HPAAtMaxReplicas`
  - Infra: `PVCUsageHigh`, `KubeNodeNotReady`, `CertificateExpiringSoon`
- Configurable thresholds under `alerts.*` in `values.yaml` (error rate,
  per-service p95 latency, crash loop restarts, PVC usage, cert expiry)
- `inhibitRules` in `AlertmanagerConfig`: root-cause alerts silence their
  symptoms (PodCrashLooping → HighErrorRate, AIProviderTotalOutage →
  AIProviderHighErrorRate, KubeNodeNotReady → workload alerts)

## [0.2.0] - 2026-10-16

### Added
- `internal/metrics` package with RED metrics (rate, errors, duration) and
  per-provider AI metrics
- `/metrics` endpoint on both `core-api` and `ai-service`, discovered by
  Prometheus via `ServiceMonitor`
- Grafana dashboard provisioned as ConfigMap (`ecommerce-ai-dashboard-platform`)
- Go 1.26 (required by `prometheus/client_golang` v1.25)
- `kube-prometheus-stack` deployment for local kind clusters

### Changed
- Const metric label renamed from `service` to `app` to avoid collision with
  the Kubernetes `service` label added by the ServiceMonitor

### Fixed
- Pre-initialized metric vectors no longer appear on dashboards with empty
  label values
- Prometheus CRDs (`PrometheusRule`, `ServiceMonitor`, `AlertmanagerConfig`)
  are now validated in CI via the datreeio CRDs catalog

## [0.1.0] - 2026-10-14

### Added
- Multi-provider AI fallback chain (Groq > Gemini > OpenRouter > DeepSeek)
- Extracted AI Service into its own binary (`cmd/ai-service`) with its own
  HTTP server, retry/backoff and trace propagation
- `internal/client` (HTTP client to the AI service) and `internal/tracing`
  (trace ID propagation across HTTP boundaries)
- `X-Internal-Token` auth between services
- Helm umbrella chart (`ecommerce-ai`) with three sub-charts
  (`core-api`, `ai-service`, `frontend`)
- Kubernetes manifests with `NetworkPolicy` (default-deny + per-service allow),
  `HorizontalPodAutoscaler` on `ai-service`, `PodDisruptionBudget` on all
  deployments, and Pod Security Standards (`runAsNonRoot`,
  `readOnlyRootFilesystem`, `drop: ALL`)
- `kind` cluster bootstrap with `ingress-nginx` and `stakater/reloader`
- GitHub Actions CI with `helm-validate` job (kubeconform + CRD catalog)

[Unreleased]: https://github.com/bolitaria/ecommerce-ai-description-generator/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bolitaria/ecommerce-ai-description-generator/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bolitaria/ecommerce-ai-description-generator/releases/tag/v0.1.0
