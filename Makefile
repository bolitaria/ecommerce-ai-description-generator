# ==============================================================================
# ecommerce-ai — local development Makefile
# ==============================================================================
# Targets are grouped:
#   - Quality:      test, lint, vet, fmt
#   - Helm:         helm-lint, helm-deps, helm-template
#   - Cluster:      kind-create, kind-delete, ingress-install, reloader-install
#   - Monitoring:   monitoring-install, monitoring-uninstall
#   - Images:       build, load
#   - Deploy:       k8s-deploy, k8s-undeploy
#   - Verification: k8s-status, k8s-port-forward, k8s-verify-alerts
#   - All-in-one:   bootstrap, teardown
# ==============================================================================

SHELL := /bin/bash
CLUSTER_NAME    ?= ecommerce-ai
NAMESPACE       ?= ecommerce-ai
MONITORING_NS   ?= monitoring
RELEASE_NAME    ?= ecommerce-ai
KPS_RELEASE     ?= kps
VALUES          ?= helm/ecommerce-ai/values-dev.yaml
IMAGE_TAG       ?= dev

.PHONY: help
help:
	@echo "ecommerce-ai — available targets:"
	@echo ""
	@echo "  Quality:"
	@echo "    test              Run Go tests + frontend build"
	@echo "    vet               go vet"
	@echo "    lint              golangci-lint"
	@echo "    fmt               gofmt + goimports"
	@echo ""
	@echo "  Helm:"
	@echo "    helm-lint         Lint all charts"
	@echo "    helm-deps         Update chart dependencies"
	@echo "    helm-template     Render the umbrella chart"
	@echo ""
	@echo "  Cluster:"
	@echo "    kind-create       Create the local kind cluster"
	@echo "    kind-delete       Delete the local kind cluster"
	@echo "    ingress-install   Install ingress-nginx"
	@echo "    reloader-install  Install stakater/reloader"
	@echo ""
	@echo "  Monitoring:"
	@echo "    monitoring-install         Install full kube-prometheus-stack"
	@echo "    monitoring-install-minimal Install only Prometheus + Alertmanager + KSM (no Grafana)"
	@echo "    monitoring-uninstall       Uninstall kube-prometheus-stack"
	@echo ""
	@echo "  Images:"
	@echo "    build             Build all Docker images locally"
	@echo "    load              Load all images into kind"
	@echo ""
	@echo "  Deploy:"
	@echo "    k8s-deploy        Install the umbrella chart"
	@echo "    k8s-undeploy      Uninstall the umbrella chart"
	@echo ""
	@echo "  Verification:"
	@echo "    k8s-status        Show pods, services, ingress, hpa, pdb, netpol"
	@echo "    k8s-port-forward  Port-forward the frontend to localhost:8090"
	@echo "    k8s-verify-alerts Check that Prometheus loaded the rules (inline)"
	@echo "    verify-alerts     Same as k8s-verify-alerts but via scripts/verify-alerts.sh"
	@echo ""
	@echo "  All-in-one:"
	@echo "    bootstrap         kind-create + ingress + reloader + monitoring + build + load + k8s-deploy"
	@echo "    teardown          k8s-undeploy + monitoring-uninstall + kind-delete"
	@echo ""

# ------------------------------------------------------------------------------
# Quality
# ------------------------------------------------------------------------------
.PHONY: test vet lint fmt
test:
	go build ./... && go test ./...
	cd web && npm ci && npm run lint && npm run build

vet:
	go vet ./...

lint:
	golangci-lint run --timeout=3m ./...

fmt:
	gofmt -w $$(find . -name '*.go' -not -path './web/node_modules/*')
	goimports -w $$(find . -name '*.go' -not -path './web/node_modules/*') 2>/dev/null || true

# ------------------------------------------------------------------------------
# Helm
# ------------------------------------------------------------------------------
.PHONY: helm-lint helm-deps helm-template
helm-lint:
	helm lint helm/charts/common
	helm lint helm/ecommerce-ai

helm-deps:
	@for chart in helm/ecommerce-ai/charts/*/; do \
		echo "==> helm dependency update $$chart"; \
		helm dependency update "$$chart"; \
	done
	helm dependency update helm/ecommerce-ai

helm-template: helm-deps
	helm template $(RELEASE_NAME) helm/ecommerce-ai -f $(VALUES)

# ------------------------------------------------------------------------------
# Cluster
# ------------------------------------------------------------------------------
.PHONY: kind-create kind-delete ingress-install reloader-install
kind-create:
	@if kind get clusters 2>/dev/null | grep -q '^$(CLUSTER_NAME)$$'; then \
		echo "cluster $(CLUSTER_NAME) already exists"; \
	else \
		kind create cluster --config k8s/kind-config.yaml --name $(CLUSTER_NAME); \
	fi

kind-delete:
	kind delete cluster --name $(CLUSTER_NAME) || true

ingress-install:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=180s

reloader-install:
	helm repo add stakater https://stakater.github.io/stakater-charts 2>/dev/null || true
	helm repo update >/dev/null
	helm upgrade --install reloader stakater/reloader \
		--namespace reloader --create-namespace \
		--set reloader.watchGlobally=false

# ------------------------------------------------------------------------------
# Monitoring
# ------------------------------------------------------------------------------
.PHONY: monitoring-install monitoring-uninstall

.PHONY: monitoring-install-minimal
monitoring-install-minimal:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
	helm repo update >/dev/null
	helm upgrade --install $(KPS_RELEASE) prometheus-community/kube-prometheus-stack \
		--namespace $(MONITORING_NS) --create-namespace \
		--set grafana.enabled=false \
		--set nodeExporter.enabled=false \
		--set prometheus-node-exporter.enabled=false \
		--set defaultRules.create=false \
		--set kubeApiServer.enabled=false \
		--set kubeControllerManager.enabled=false \
		--set kubeScheduler.enabled=false \
		--set kubeEtcd.enabled=false \
		--set kubeProxy.enabled=false \
		--set kubelet.enabled=false \
		--set coreDns.enabled=false \
		--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
		--set alertmanager.alertmanagerSpec.alertmanagerConfigSelectorNilUsesHelmValues=false \
		--set alertmanager.alertmanagerSpec.alertmanagerConfigMatcherStrategy.type=None \
		--set prometheus.prometheusSpec.retention=6h \
		--set prometheus.prometheusSpec.resources.requests.cpu=100m \
		--set prometheus.prometheusSpec.resources.requests.memory=256Mi \
		--set prometheus.prometheusSpec.resources.limits.cpu=500m \
		--set prometheus.prometheusSpec.resources.limits.memory=1Gi

monitoring-install:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
	helm repo update >/dev/null
	helm upgrade --install $(KPS_RELEASE) prometheus-community/kube-prometheus-stack \
		--namespace $(MONITORING_NS) --create-namespace \
		--set grafana.adminPassword=admin \
		--set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
		--set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false \
		--set alertmanager.alertmanagerSpec.alertmanagerConfigSelectorNilUsesHelmValues=false \
		--set alertmanager.alertmanagerSpec.alertmanagerConfigMatcherStrategy.type=None \
		--set prometheus.prometheusSpec.retention=6h \
		--set prometheus.prometheusSpec.resources.requests.cpu=100m \
		--set prometheus.prometheusSpec.resources.requests.memory=256Mi \
		--set prometheus.prometheusSpec.resources.limits.cpu=500m \
		--set prometheus.prometheusSpec.resources.limits.memory=1Gi

monitoring-uninstall:
	helm uninstall $(KPS_RELEASE) --namespace $(MONITORING_NS) || true
	kubectl delete namespace $(MONITORING_NS) --ignore-not-found

# ------------------------------------------------------------------------------
# Images
# ------------------------------------------------------------------------------
.PHONY: build load
build:
	docker build -f Dockerfile            -t backend:$(IMAGE_TAG) .
	docker build -f Dockerfile.ai-service -t ai-service:$(IMAGE_TAG) .
	docker build -f Dockerfile.frontend   -t frontend:$(IMAGE_TAG) .
	docker build -f Dockerfile.mock       -t mock-deepseek:$(IMAGE_TAG) .

load:
	kind load docker-image backend:$(IMAGE_TAG)       --name $(CLUSTER_NAME)
	kind load docker-image ai-service:$(IMAGE_TAG)    --name $(CLUSTER_NAME)
	kind load docker-image frontend:$(IMAGE_TAG)      --name $(CLUSTER_NAME)
	kind load docker-image mock-deepseek:$(IMAGE_TAG) --name $(CLUSTER_NAME)

# ------------------------------------------------------------------------------
# Deploy
# ------------------------------------------------------------------------------
.PHONY: k8s-deploy k8s-undeploy
k8s-deploy: helm-deps
	helm upgrade --install $(RELEASE_NAME) helm/ecommerce-ai \
		--namespace $(NAMESPACE) --create-namespace \
		-f $(VALUES) \
		--wait --timeout 5m

k8s-undeploy:
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) || true
	kubectl delete namespace $(NAMESPACE) --ignore-not-found

# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------
.PHONY: k8s-status k8s-port-forward k8s-verify-alerts

.PHONY: verify-alerts
verify-alerts:
	./scripts/verify-alerts.sh 8

k8s-status:
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE)
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n $(NAMESPACE)
	@echo ""
	@echo "=== Ingress ==="
	kubectl get ingress -n $(NAMESPACE)
	@echo ""
	@echo "=== HPA ==="
	kubectl get hpa -n $(NAMESPACE)
	@echo ""
	@echo "=== PDB ==="
	kubectl get pdb -n $(NAMESPACE)
	@echo ""
	@echo "=== NetworkPolicy ==="
	kubectl get netpol -n $(NAMESPACE)
	@echo ""
	@echo "=== PrometheusRule ==="
	kubectl get prometheusrule -n $(NAMESPACE) 2>/dev/null || echo "none"
	@echo ""
	@echo "=== AlertmanagerConfig ==="
	kubectl get alertmanagerconfig -n $(NAMESPACE) 2>/dev/null || echo "none"

k8s-port-forward:
	@echo "Forwarding frontend to http://localhost:8090 ..."
	kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-frontend 8090:80 --address=0.0.0.0

k8s-verify-alerts:
	@echo "=== Alert rules loaded in Prometheus ==="
	@pkill -f "port-forward.*9090" 2>/dev/null || true
	@sleep 1
	@kubectl port-forward -n $(MONITORING_NS) svc/$(KPS_RELEASE)-kube-prometheus-stack-prometheus 9090:9090 > /tmp/pf-prom.log 2>&1 & \
		PF_PID=$$!; \
		sleep 5; \
		curl -s 'http://localhost:9090/api/v1/rules?type=alert' | \
			jq -r '.data.groups[] | .name as $$g | .rules[] | "\($$g) | \(.name) | \(.state)"'; \
		kill $$PF_PID 2>/dev/null || true

# ------------------------------------------------------------------------------
# All-in-one
# ------------------------------------------------------------------------------
.PHONY: bootstrap teardown
bootstrap: kind-create ingress-install reloader-install monitoring-install build load k8s-deploy
	@echo ""
	@echo "=== Bootstrap complete ==="
	@$(MAKE) k8s-status

teardown: k8s-undeploy monitoring-uninstall kind-delete
	@echo "=== Teardown complete ==="
