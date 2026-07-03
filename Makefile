.PHONY: help build test lint docker-build docker-run docker-stop clean migrate-up gen release monitoring-up monitoring-down

APP_NAME := ecommerce-ai-description-generator

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Compile backend
	go build -ldflags="-s -w" -o $(APP_NAME) ./cmd/server

test: ## Run unit tests
	go test -v -race -coverprofile=coverage.out $$(go list ./... | grep -v /web/)

lint: ## Lint Go code
	golangci-lint run --timeout=3m

docker-build: ## Build Docker images
	docker-compose build

docker-run: ## Start full stack
	docker-compose up -d

docker-stop: ## Stop all services
	docker-compose down

clean: ## Remove build artifacts
	rm -f $(APP_NAME) coverage.out coverage.html

migrate-up: ## Apply database migrations
	go run cmd/migrate/main.go up

gen: ## Generate code (wire, swag)
	go generate ./...

release: ## Create new release (semantic-release)
	npx semantic-release

monitoring-up: ## Start Prometheus + Grafana
	docker-compose -f deploy/monitoring/docker-compose.yml up -d

monitoring-down: ## Stop monitoring stack
	docker-compose -f deploy/monitoring/docker-compose.yml down
