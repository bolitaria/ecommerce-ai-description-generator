#!/bin/bash
set -e
# This script uses gcloud CLI, assumes service account and project are configured.
SERVICE_NAME=${1:-ecommerce-backend}
REGION=${2:-us-central1}
IMAGE=${3:-ghcr.io/your-org/backend:latest}
gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --set-env-vars "DATABASE_URL=$DATABASE_URL,JWT_SECRET=$JWT_SECRET,ENV=production" \
  --set-secrets "OPENAI_API_KEY=openai-api-key:latest"
