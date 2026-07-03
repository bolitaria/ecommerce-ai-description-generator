variable "project_id" {
  description = "GCP project ID"
}
variable "region" {
  description = "GCP region"
  default     = "us-central1"
}
variable "service_name" {
  description = "Cloud Run service name"
  default     = "ecommerce-backend"
}
variable "backend_image" {
  description = "Docker image for backend"
}
variable "database_url" {
  description = "PostgreSQL connection string"
}
variable "jwt_secret" {
  description = "JWT signing secret"
  sensitive   = true
}
