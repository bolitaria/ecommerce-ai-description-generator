#!/bin/bash
set -euo pipefail

PROJECT_ID="${1:-}"
REGION="${2:-us-central1}"
SERVICE_NAME="ecommerce-ai-description-generator"

if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 <GCP_PROJECT_ID> [REGION]"
  exit 1
fi

echo "Building and pushing Docker image..."
gcloud builds submit --tag "gcr.io/$PROJECT_ID/$SERVICE_NAME"

echo "Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/$PROJECT_ID/$SERVICE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --set-env-vars "DeepSeek_API_KEY=$(gcloud secrets versions access latest --secret=deepseek-api-key)" \
  --memory 256Mi \
  --cpu 1 \
  --max-instances 10 \
  --concurrency 80 \
  --timeout=30

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --format='value(status.url)')
echo "Deployment complete. Service URL: $SERVICE_URL"
