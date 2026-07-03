cat > README.txt <<'EOF'
E-commerce AI Description Generator
====================================

A production-ready microservice and admin panel that automates content for online sellers using AI.
Built with Go, React + TypeScript, and Docker. Fully tested, monitored, and CI/CD-enabled.

FEATURES

- Product Management: Add, edit, delete products; assign them to departments.
- AI Description Generator: Generate compelling product descriptions with one click.
- AI Translation: Translate descriptions into Spanish, French, German, and more.
- AI Email Campaigns: Create marketing email subjects and bodies automatically.
- Dashboard: Real-time metrics (total products, departments, orders, revenue) from the database.
- Search & Filter: Filter by department, search by name; paginated results.
- Security: CORS, rate limiting, panic recovery, request tracing (X-Trace-ID).
- Cloud-ready: Multi-stage Docker builds, Docker Compose, GitHub Actions CI/CD, ready for GCP Cloud Run.
- Monitoring: Prometheus metrics endpoint, optional Grafana stack.
- Provider-agnostic AI: Works with OpenAI, DeepSeek, Groq, Mistral, or any OpenAI-compatible API.

TECH STACK

Backend: Go, PostgreSQL (via pgx), net/http
Frontend: React, TypeScript, Vite, React Query, React Hook Form, Zod
AI: OpenAI-compatible API (DeepSeek, Groq, etc.)
DevOps: Docker, Docker Compose, GitHub Actions, Makefile, Terraform (GCP)
Monitoring: Prometheus + Grafana (optional)

PROJECT STRUCTURE

cmd/
  server/        Backend entry point
  mockopenai/    Mock AI server for testing
internal/
  config/        Environment-based configuration
  db/            Database initialization and migrations
  handler/       HTTP handlers (CRUD, AI endpoints)
  middleware/     CORS, logging, rate limiting, recovery
  openai/        AI client interface + circuit breaker
  server/        Server setup, graceful shutdown
  domain/        Business logic interfaces
  repository/    PostgreSQL implementations
  service/       Application services
  auth/          JWT authentication
  telemetry/     OpenTelemetry tracing
web/             Frontend source (React + TypeScript)
Dockerfile       Backend multi-stage build (distroless)
Dockerfile.frontend  Frontend build (nginx)
Dockerfile.mock  Mock OpenAI server
docker-compose.yml   Full stack orchestration
deploy/          Production Docker Compose, Terraform, monitoring configs
scripts/         Deployment, migration, security, and release scripts
.github/workflows/   CI/CD pipeline

QUICK START

Prerequisites: Docker and Docker Compose.

1. Clone the repository:
   git clone https://github.com/bolitaria/ecommerce-ai-description-generator.git
   cd ecommerce-ai-description-generator

2. Configure environment:
   cp .env.example .env
   Edit .env to add your API keys (optional; mock works out of the box).

3. Run with Docker Compose:
   docker-compose up --build

4. Access the application:
   Frontend: http://localhost:5173
   Backend API: http://localhost:8080
   Health check: http://localhost:8080/health

The database is pre-seeded with 6 demo products across 5 departments.

USING A REAL AI PROVIDER

Edit .env with your credentials. Example for Groq (free tier):

OPENAI_API_KEY=gsk_your_key_here
OPENAI_URL=https://api.groq.com/openai/v1
OPENAI_MODEL=llama3-8b-8192
ENV=production

Then rebuild:
docker-compose down
docker-compose up --build

API ENDPOINTS

Prefix: /api/v1

GET    /health                Health check
GET    /departments           List all departments
GET    /products              List products (with filters & pagination)
POST   /products              Create a product
PUT    /products/:id          Update a product
DELETE /products/:id          Delete a product
POST   /generate              Generate product description (AI)
POST   /translate             Translate text (AI)
POST   /email                 Generate marketing email (AI)

Query parameters for GET /products: department_id, search, page, limit.
Response includes total count and pagination metadata.

TESTING & QUALITY

Run Go unit tests (excluding web/):
  go test -v -race -coverprofile=coverage.out $(go list ./... | grep -v /web/ | grep -v /tests)

Run integration tests (requires a test PostgreSQL):
  export TEST_DATABASE_URL=postgres://test:test@localhost:5432/testdb?sslmode=disable
  go test -v ./tests/integration/...

Lint Go code:
  golangci-lint run --timeout=3m

Security checks:
  govulncheck ./...
  gosec ./...
  cd web && npm audit

Build frontend:
  cd web && npm run build

Use the provided Makefile for convenience:
  make test        run tests + generate coverage
  make lint        lint Go code
  make build       compile backend binary

DEPLOYMENT

Google Cloud Run (via script):
  make deploy GCP_PROJECT=my-gcp-project-id REGION=us-central1

The script uses Cloud Build, Container Registry, and Cloud Run with secrets from Secret Manager.

Terraform infrastructure (optional):
  cd deploy/terraform
  terraform init && terraform apply

Production Docker Compose:
  docker-compose -f deploy/docker-compose.prod.yml up -d

MONITORING

Start Prometheus and Grafana:
  make monitoring-up

Grafana: http://localhost:3000 (admin/admin)
Prometheus: http://localhost:9090

Backend exposes /metrics endpoint (Prometheus-compatible). Dashboards and alert rules are preconfigured.

ARCHITECTURE

The system follows Clean Architecture principles:
- Domain interfaces define business rules.
- Repositories implement data access (PostgreSQL).
- Services orchestrate use cases.
- Handlers are thin HTTP adapters.
- AI client is abstracted behind an interface with circuit breaker and retry logic.

Authentication is JWT-based (optional, can be enabled by adding the middleware). Tracing uses OpenTelemetry, configurable via environment.

DOCUMENTATION

Runbook: deploy/runbook.md (commands for daily operations)
CI/CD Pipeline: .github/workflows/ci.yml
Environment template: .env.example
API documentation: automatically generated with Swagger (/docs endpoint if enabled)

LICENSE

MIT License. See LICENSE file.

BUILT BY

Bolitaria
EOF