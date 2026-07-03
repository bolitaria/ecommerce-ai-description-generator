#!/bin/bash
set -e
echo "Generating Swagger..."
swag init -g cmd/server/main.go -o api/docs
echo "Generating Wire..."
cd internal && wire && cd ..
