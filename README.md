# 🛒 E-commerce AI Description Generator

> **A production‑ready microservice and admin panel that automates content for online sellers using AI.**  
> Built with **Go**, **React + TypeScript**, and **Docker**. Fully tested, monitored, and CI/CD‑enabled.

[![CI/CD Pipeline](https://github.com/bolitaria/ecommerce-ai-description-generator/actions/workflows/ci.yml/badge.svg)](https://github.com/bolitaria/ecommerce-ai-description-generator/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features

- **Product Management** – Add, edit, delete products; assign them to departments.
- **AI Description Generator** – Generate compelling product descriptions with a single click.
- **AI Translation** – Translate descriptions into Spanish, French, German, and more.
- **AI Email Campaigns** – Create marketing email subjects and bodies automatically.
- **Dashboard** – Real‑time metrics (total products, departments) from the database.
- **Search & Filter** – Filter by department, search by name; paginated results.
- **Security** – CORS, rate limiting, panic recovery, request tracing (`X-Trace-ID`).
- **Cloud‑ready** – Multi‑stage Docker builds, Docker Compose, GitHub Actions CI/CD, ready for GCP Cloud Run.
- **Monitoring** – Prometheus metrics endpoint, optional Grafana stack.
- **Provider‑agnostic AI** – Works with OpenAI, DeepSeek, Groq, Mistral, or any OpenAI‑compatible API.

---

## 🧰 Tech Stack

| Layer       | Technology                                              |
|-------------|---------------------------------------------------------|
| **Backend** | Go, SQLite (via `modernc.org/sqlite`), `net/http`       |
| **Frontend**| React, TypeScript, Vite, CSS modules                    |
| **AI**      | OpenAI‑compatible API (DeepSeek, Groq, etc.)            |
| **DevOps**  | Docker, Docker Compose, GitHub Actions, Makefile, GCP Cloud Run |
| **Monitoring** | Prometheus + Grafana (optional)                     |

---

## 📁 Project Structure
ecommerce-ai-description-generator/
├── cmd/
│ ├── server/ # Backend entry point
│ └── mockopenai/ # Mock AI server for testing
├── internal/
│ ├── config/ # Environment‑based configuration
│ ├── db/ # Database models, migration, seed
│ ├── handler/ # HTTP handlers (CRUD, AI endpoints)
│ ├── middleware/ # CORS, logging, rate limiting, recovery
│ ├── openai/ # AI client interface + implementation
│ └── server/ # Server setup, graceful shutdown
├── web/ # Frontend (React + TypeScript)
│ └── src/
│ ├── components/ # Dashboard, Products, AI Tools, etc.
│ └── ...
├── Dockerfile # Backend multi‑stage build (distroless)
├── Dockerfile.frontend # Frontend build (nginx)
├── Dockerfile.mock # Mock OpenAI server
├── docker-compose.yml # Full stack orchestration
├── Makefile # Build, test, deploy shortcuts
├── .github/workflows/ # CI/CD pipeline
├── deploy/ # Production Compose + monitoring stack
└── scripts/ # Deployment & migration scripts

text

---

## 🚀 Quick Start

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)
- (Optional) An API key from [DeepSeek](https://platform.deepseek.com), [Groq](https://console.groq.com), or OpenAI

### 1. Clone and configure
```bash
git clone https://github.com/bolitaria/ecommerce-ai-description-generator.git
cd ecommerce-ai-description-generator
cp .env.example .env   # edit to add API keys (optional)
2. Run with Docker Compose
bash
docker-compose up --build
Access points:

Frontend: http://localhost:5173

Backend API: http://localhost:8080

Health check: http://localhost:8080/health

The database is pre‑seeded with 6 demo products across 5 departments.

3. Use a real AI provider (optional)
Edit .env with your credentials. Example for Groq (free tier):

ini
OPENAI_API_KEY=gsk_your_key_here
OPENAI_URL=https://api.groq.com/openai/v1
OPENAI_MODEL=llama3-8b-8192
ENV=production
Then rebuild:

bash
docker-compose down
docker-compose up --build
🔌 API Endpoints
Method	Path	Description
GET	/health	Health check
GET	/api/departments	List all departments
GET	/api/products	List products (with filters & pagination)
POST	/api/products	Create a product
PUT	/api/products/:id	Update a product
DELETE	/api/products/:id	Delete a product
POST	/generate	Generate product description (AI)
POST	/translate	Translate text (AI)
POST	/email	Generate marketing email (AI)
Query parameters for GET /api/products:

department_id – filter by department

search – search by product name

page & limit – pagination (default 10 per page)
Response includes X-Total-Count header for pagination.

🧪 Testing & Quality
bash
# Run unit tests (skips web/ directory)
go test -v -race -coverprofile=coverage.out $(go list ./... | grep -v /web/)

# HTML coverage report
go tool cover -html=coverage.out -o coverage.html

# Lint (requires golangci-lint installed)
golangci-lint run --timeout=3m
Use the provided Makefile for convenience:

bash
make test        # run tests + generate coverage
make lint        # lint Go code
make build       # compile backend binary
☁️ Deployment
Google Cloud Run (via script)
bash
# Set your GCP project and region
make deploy GCP_PROJECT=my-gcp-project-id REGION=us-central1
The script uses Cloud Build, pushes to Container Registry, and deploys to Cloud Run with API keys from Secret Manager.

Production Docker Compose
An example production stack (without mock) is available in deploy/docker-compose.prod.yml.

📊 Monitoring (Optional)
Start Prometheus and Grafana with:

bash
make monitoring-up
Grafana: http://localhost:3000 (admin/admin)

Prometheus: http://localhost:9090

The backend exposes a /metrics endpoint (can be instrumented with the Prometheus client library). Configuration files are in deploy/monitoring/.

Stop with:

bash
make monitoring-down
📄 Documentation
Runbook – day‑to‑day commands and troubleshooting.

CI/CD Pipeline – automated tests, Docker builds, and Cloud Run deploy.

.env.example – template for environment variables.

📝 License
This project is licensed under the MIT License – see the LICENSE file for details.

🙋‍♂️ About
This project was built to demonstrate how a modern e‑commerce AI tool can be developed with Go, React, Docker, and a provider‑agnostic AI architecture.
It is directly aligned with the kind of tools built at Sticker Mule, showcasing the ability to move fast, integrate AI aggressively, and deliver production‑ready software.

Built with ❤️
