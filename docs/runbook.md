# Operational Runbook

## Purpose

This document gathers the recommended steps for developing, testing, validating quality, and deploying the application consistently in local and CI/CD environments.

## Prerequisites

- Docker and Docker Compose
- Go 1.25+
- Node.js 20+
- Make
- Optional: golangci-lint, gosec, govulncheck

## Quick start for the local environment

### Option 1: Docker Compose

```bash
docker-compose up --build
```

### Option 2: Makefile

```bash
make docker-build
make docker-run
```

### Expected services

- Frontend: http://localhost:5173
- Backend API: http://localhost:8080
- Health check: http://localhost:8080/health

### Stop the environment

```bash
make docker-stop
```

## Testing scripts and commands

### Backend (Go)

Run the full test suite:

```bash
go test ./...
```

Run with the race detector and generate coverage:

```bash
go test -v -race -coverprofile=coverage.out ./...
```

Run integration tests if PostgreSQL is available:

```bash
export TEST_DATABASE_URL=postgres://test:test@localhost:5432/testdb?sslmode=disable
go test -v ./tests/integration/...
```

### Frontend (React + TypeScript)

```bash
cd web
npm ci
npm run lint
npm run build
```

### Makefile commands

```bash
make test
make lint
make build
```

## Code quality and review

### Go lint

```bash
make lint
```

### Additional recommended checks

```bash
gosec ./...
govulncheck ./...
cd web && npm audit
```

## CI/CD

The project uses GitHub Actions to validate changes and publish images.

### Available workflows

- .github/workflows/ci.yml: main continuous integration and deployment pipeline
- .github/workflows/.golangci.yml: Go lint configuration

### What the pipeline runs

1. Backend test
   - Installs Go
   - Starts PostgreSQL as a test service
   - Runs lint and tests

2. Frontend test
   - Installs Node.js
   - Runs npm ci, lint, and build

3. Build and push
   - Builds Docker images and publishes them to GitHub Container Registry

4. Deploy
   - Runs on main and deploys to Cloud Run when the required secrets are configured

### Expected secrets

The following variables are required:

- GCP_SA_KEY
- CLOUD_RUN_SERVICE
- GCP_REGION
- DATABASE_URL
- DeepSeek_API_KEY
- JWT_SECRET

## Deployment

### Local deployment with Docker Compose

```bash
docker-compose -f deploy/docker-compose.prod.yml up -d
```

### Deployment with Terraform

```bash
cd deploy/terraform
terraform init
terraform apply
```

## Troubleshooting

### Docker Compose fails to start

- Verify that Docker is running
- Confirm that ports 5173, 8080, and 5432 are free
- Review the .env file

### Database connection issues

- Verify that PostgreSQL is available
- Confirm that DATABASE_URL or TEST_DATABASE_URL is correct
- Review the logs of the database container

### CI failures

- Re-run the same commands locally
- Review the GitHub Actions workflow logs
- Validate that the secrets are configured correctly

## Recommended daily workflow

1. Run local tests before opening a PR
2. Review frontend lint and build
3. Confirm that the application starts correctly with Docker
4. Push changes and verify the pipeline in GitHub Actions
