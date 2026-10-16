{{/*
Umbrella-specific helpers.
Cross-chart helpers (labels, image, secretName) live in the `common` library chart.
*/}}

{{/*
Backend Service name (rendered by the core-api sub-chart).
*/}}
{{- define "ecommerce-ai.coreApiService" -}}
{{- printf "%s-core-api" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
AI Service name (rendered by the ai-service sub-chart).
*/}}
{{- define "ecommerce-ai.aiServiceService" -}}
{{- printf "%s-ai-service" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Frontend Service name (rendered by the frontend sub-chart).
*/}}
{{- define "ecommerce-ai.frontendService" -}}
{{- printf "%s-frontend" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
