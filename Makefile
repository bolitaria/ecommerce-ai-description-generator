.PHONY: help test helm-lint helm-deps helm-template kind-create kind-delete k8s-deploy k8s-undeploy

help:
	@echo "Targets:"
	@echo "  test            - run Go + frontend tests"
	@echo "  helm-lint       - lint all charts"
	@echo "  helm-deps       - update dependencies for all sub-charts"
	@echo "  helm-template   - render the umbrella chart to stdout"
	@echo "  kind-create     - create a local kind cluster"
	@echo "  kind-delete     - delete the local kind cluster"
	@echo "  k8s-deploy      - install the umbrella chart into the cluster"
	@echo "  k8s-undeploy    - uninstall the umbrella chart"

test:
	go build ./... && go test ./...
	cd web && npm ci && npm run lint && npm run build

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
	helm template ecommerce-ai helm/ecommerce-ai -f helm/ecommerce-ai/values-dev.yaml

kind-create:
	@if kind get clusters 2>/dev/null | grep -q '^ecommerce-ai$$'; then \
		echo "cluster ecommerce-ai already exists"; \
	else \
		kind create cluster --config k8s/kind-config.yaml; \
	fi

kind-delete:
	kind delete cluster --name ecommerce-ai

k8s-deploy: helm-deps
	helm upgrade --install ecommerce-ai helm/ecommerce-ai \
		--namespace ecommerce-ai --create-namespace \
		-f helm/ecommerce-ai/values-dev.yaml

k8s-undeploy:
	helm uninstall ecommerce-ai --namespace ecommerce-ai || true
	kubectl delete namespace ecommerce-ai --ignore-not-found
