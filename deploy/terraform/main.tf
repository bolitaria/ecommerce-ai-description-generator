terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_secret_manager_secret" "openai_key" {
  secret_id = "openai-api-key"
  replication {
    auto {}
  }
}

resource "google_cloud_run_v2_service" "backend" {
  name     = var.service_name
  location = var.region

  template {
    containers {
      image = var.backend_image
      env {
        name  = "DATABASE_URL"
        value = var.database_url
      }
      env {
        name = "OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.openai_key.secret_id
            version = "latest"
          }
        }
      }
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
      env {
        name  = "ENV"
        value = "production"
      }
      ports {
        container_port = 8080
      }
    }
  }
}

output "service_url" {
  value = google_cloud_run_v2_service.backend.uri
}
