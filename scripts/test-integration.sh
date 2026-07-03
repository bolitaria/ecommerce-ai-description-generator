#!/bin/bash
set -e
echo "Running integration tests..."
# Assumes TEST_DATABASE_URL is set to a test Postgres instance.
go test -v -count=1 ./tests/integration/...
