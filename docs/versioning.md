# Versioning strategy

## Three independent version numbers

The project uses three version numbers that change for different reasons.
Confusing them is a common source of accidental rollouts and unreproducible
deployments.

| Version | Lives in | Bumps when | Bumps who |
|---|---|---|---|
| **App version** | `Chart.yaml appVersion` | New behaviour of the binary | Developer, per release |
| **Chart version** | `Chart.yaml version` | New Helm template or default values | Developer, per release |
| **Image tag** | `values-{env}.yaml imageTag` | Every image build | CI (uses `sha-<commit>`) |

## App version (SemVer)

Follows [Semantic Versioning](https://semver.org):

- **MAJOR** (`v2.0.0`): incompatible API change.
- **MINOR** (`v1.1.0`): backwards-compatible feature.
- **PATCH** (`v1.0.1`): backwards-compatible bug fix.

Lives in each sub-chart's `Chart.yaml` under `appVersion`, and in the
`CHANGELOG.md`.

## Chart version

Follows SemVer independently from the app version. Bumps when Helm templates
or default values change — even if the app itself didn't change.

Examples:

- Adding a new alert → minor bump (`0.1.0 → 0.2.0`).
- Fixing a typo in a template → patch bump (`0.2.0 → 0.2.1`).
- Changing the values schema (breaking) → major bump (`0.2.1 → 1.0.0`).

The chart version is what consumers see when they run `helm search` or
`helm list`. It should be bumped in every PR that touches `helm/`.

## Image tag

Every CI build publishes **two tags** to GHCR:

```
ghcr.io/bolitaria/ecommerce-ai-description-generator/backend:latest
ghcr.io/bolitaria/ecommerce-ai-description-generator/backend:sha-<commit>
```

- `:latest` is mutable. Used only for local dev. **Never deployed to
  production.**
- `:sha-<commit>` is immutable. **Always used in production.** Enables
  deterministic rollback.

`values-dev.yaml` points to `:latest`. `values-prod.yaml` requires a specific
`sha-` tag at deploy time (the variable is empty by default and fails fast if
not set — see the `if cfg.AIServiceURL == ""` style checks in the binaries).

## Git tags

When a release is ready, tag the commit:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

The tag triggers `.github/workflows/release.yml`, which:

1. Builds and publishes multi-arch images (`linux/amd64,linux/arm64`) tagged
   `v1.0.0` and `sha-<commit>`.
2. Creates a GitHub Release with auto-generated notes.

Multi-arch matters because Oracle Cloud Always Free runs on ARM (Ampere A1),
and the local kind cluster runs on amd64. A single `sha-<commit>` must work on
both.

## CHANGELOG

Follows [Keep a Changelog](https://keepachangelog.com). Every PR that changes
behaviour updates the `[Unreleased]` section. When cutting a release, the
`[Unreleased]` section moves to the version heading with the release date.

Sections used:

- `Added` — new features.
- `Changed` — changes to existing behaviour.
- `Deprecated` — soon-to-be-removed features.
- `Removed` — removed features.
- `Fixed` — bug fixes.
- `Security` — vulnerability fixes.

## Kubernetes labels and versioning

The Helm charts follow the
[recommended Kubernetes labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/):

| Label | Value | Notes |
|---|---|---|
| `helm.sh/chart` | `<chart-name>-<chart-version>` | Managed by Helm. Changes with every chart bump. |
| `app.kubernetes.io/name` | `<service>` (e.g. `core-api`) | **Immutable in the Deployment selector.** |
| `app.kubernetes.io/instance` | Release name (e.g. `ecommerce-ai`) | **Immutable in the Deployment selector.** |
| `app.kubernetes.io/version` | `appVersion` | Changes with app version bumps. |
| `app.kubernetes.io/managed-by` | `Helm` | Set by Helm. |
| `app.kubernetes.io/part-of` | `ecommerce-ai` | Product grouping. |

### Critical rule: selector labels are immutable

The `selector.matchLabels` of a `Deployment` is **immutable** in Kubernetes.
Adding `version` or `chart` to the selector would require deleting and
recreating the Deployment on every release, causing downtime.

The selector therefore only contains the stable labels:

```yaml
selector:
  matchLabels:
    app.kubernetes.io/name: core-api
    app.kubernetes.io/instance: ecommerce-ai
```

Everything else (`helm.sh/chart`, `app.kubernetes.io/version`) goes on the
**Deployment metadata and Pod template**, never on the selector.

### Known issue: version labels on the Pod template

Currently the Pod template includes `helm.sh/chart` and
`app.kubernetes.io/version`. This means **bumping the chart or app version
triggers a rolling restart of all pods**, even if the container image is
unchanged.

This is tracked as a follow-up improvement: split `common.labels` (Deployment
metadata) from `common.podLabels` (Pod template) so that version labels do
not force a restart. The change is low-risk but requires its own PR because
it triggers a one-time rolling restart of every deployment.

## Why this matters

- **Reproducibility.** A given `sha-<commit>` image is byte-identical across
  environments. A given `values-prod.yaml` + chart version produces the same
  cluster state.
- **Rollback.** Reverting a bad deployment is one `git revert`. The chart
  version, image tag, and app version all move together.
- **Audit.** Every deployment traces back to a specific commit, a specific
  chart version, and a specific image tag. If an incident happens, you can
  reconstruct exactly what was running.

## What we deliberately do NOT do

- **No `:latest` in production values.** Enforced by `values-prod.yaml`
  leaving `imageTag` empty.
- **No version in Deployment selector labels.** The selector is immutable in
  Kubernetes; adding a version there would require deleting and recreating
  the Deployment on every release.
- **No shared version across all services.** Each service has its own
  `appVersion`. The `ai-service` may be at `1.2.0` while `core-api` is still
  at `1.0.3`. Versions reflect the app, not the product.
- **No auto-bump on every commit.** Versions are bumped deliberately, in the
  PR that cuts a release. The image tag (`sha-<commit>`) is the
  per-commit identifier; the app version is the release identifier.

## Summary table

| Artifact | Identifier | Frequency | Immutable |
|---|---|---|---|
| Container image | `sha-<commit>` | Every commit | Yes |
| Container image | `:latest` | Every commit on `main` | No |
| Container image | `v1.2.3` | Every tag | Yes |
| Helm chart | `version: 0.2.0` | Every chart change | Yes (in GHCR as `.tgz`) |
| Application | `appVersion: 1.0.0` | Every release | Yes (referenced by chart) |
| Git commit | `abc1234` | Every commit | Yes |
| Git tag | `v1.0.0` | Every release | Yes |