# Ecommerce AI Description Generator

A production-ready full-stack application that helps e-commerce teams generate compelling product descriptions, localized content, and marketing copy with AI. The project combines a Go-based backend, a React and TypeScript frontend, PostgreSQL persistence, Docker-based deployment, and observability practices in a single, cohesive platform.

## Overview

This repository demonstrates how to build an AI-enabled commerce product end to end: from product management and API design to UI workflows, testing, deployment automation, and production monitoring. It is structured to be extensible, maintainable, and suitable for both local development and cloud deployment.

## Key capabilities

- Product and department management with CRUD operations
- AI-powered product description generation
- AI-assisted translation for multiple languages
- Marketing email generation based on product context
- Admin dashboard with search, filters, and pagination
- Security controls such as CORS, rate limiting, recovery middleware, and tracing
- Cloud-ready deployment with Docker Compose, CI/CD, and infrastructure automation

## Tech stack

- Backend: Go, net/http, pgx, PostgreSQL
- Frontend: React, TypeScript, Vite, React Query, React Hook Form, Zod
- AI integrations: DeepSeek-compatible providers and mock AI server support
- DevOps: Docker, Docker Compose, GitHub Actions, Terraform, Prometheus, Grafana

## Architecture

The project follows clean architecture principles with a clear separation between:

- Domain models and business rules
- Application services and use cases
- Repositories for persistence
- HTTP handlers and API adapters
- AI clients and provider abstractions

This structure makes the system easier to evolve as new capabilities are added.

## Project structure

- cmd/ - Application entry points
- internal/ - Core backend modules, services, repositories, middleware, and config
- web/ - Frontend source implemented in React and TypeScript
- deploy/ - Production deployment, Terraform, and monitoring assets
- scripts/ - Automation for build, migration, deployment, and quality checks

## Quick start

### Prerequisites

- Docker
- Docker Compose

### Run locally

1. Clone the repository:
   ```bash
   git clone https://github.com/bolitaria/ecommerce-ai-description-generator.git
   cd ecommerce-ai-description-generator
   ```

2. Start the application:
   ```bash
   docker-compose up --build
   ```

3. Open the services:
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:8080
   - Health check: http://localhost:8080/health

The database is pre-seeded with demo products and departments for immediate exploration.

## Environment configuration

Copy the environment template and provide your own credentials if you want to use a real AI provider:

```bash
cp .env.example .env
```

If no provider credentials are configured, the mock server can still be used for local testing.

## API overview

The API is organized under the /api/v1 prefix and includes endpoints for health checks, departments, products, description generation, translation, and email generation.

## Testing and quality

Run the backend test suite:

```bash
go test ./...
```

Run the frontend build:

```bash
cd web && npm run build
```

The repository also includes CI/CD workflows and deployment scripts for automated validation and delivery.

## Deployment

The project includes assets for:

- Docker-based deployment
- Google Cloud Run automation
- Terraform infrastructure provisioning
- Prometheus and Grafana monitoring

## License

This project is licensed under the MIT License.
