#!/bin/bash
set -euo pipefail
echo "Running database migrations..."
cd "$(dirname "$0")/.."
# Currently migrations run inside InitDB.
# Add go run ./cmd/migrate/main.go here when needed.
echo "Migrations applied."
