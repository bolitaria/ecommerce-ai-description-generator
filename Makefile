# ──────────────────────────────────────────────────────
# E-commerce AI Description Generator — Makefile
# ──────────────────────────────────────────────────────
.PHONY: help build test test-cover lint docker-build docker-run docker-stop clean deploy monitoring-up monitoring-down

APP_NAME     := ecommerce-ai-description-generator
GCP_PROJECT  ?= my-gcp-project
REGION       ?= us-central1

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Compile backend binary
	go build -ldflags="-s -w" -o $(APP_NAME) ./cmd/server

test: ## Run unit tests (skip web/)
	go test -v -race -coverprofile=coverage.out $$(go list ./... | grep -v /web/) 2>&1 | tee test.log

test-cover: test ## Generate HTML coverage report
	go tool cover -html=coverage.out -o coverage.html

lint: ## Lint Go source
	golangci-lint run --timeout=3m

docker-build: ## Build all Docker images
	docker-compose build

docker-run: ## Start full stack (detached)
	docker-compose up -d
	@echo "Frontend: http://localhost:5173"
	@echo "Backend:  http://localhost:8080"
	@echo "Health:   http://localhost:8080/health"

docker-stop: ## Stop all services
	docker-compose down

clean: ## Remove build artifacts only (binary, coverage, test log)
	rm -f $(APP_NAME) coverage.out coverage.html test.log

docker-clean: docker-stop ## Remove project volumes (database will be lost)
	docker-compose down -v
	rm -rf ./data

deploy: ## Deploy backend to Cloud Run
	chmod +x scripts/deploy.sh
	./scripts/deploy.sh $(GCP_PROJECT) $(REGION)

monitoring-up: ## Start Prometheus + Grafana
	docker-compose -f deploy/monitoring/docker-compose.yml up -d
	@echo "Grafana: http://localhost:3000 (admin/admin)"

monitoring-down: ## Stop monitoring stack
	docker-compose -f deploy/monitoring/docker-compose.yml down
