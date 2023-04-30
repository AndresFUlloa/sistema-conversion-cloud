resource "google_artifact_registry_repository" "flask-api" {
  location      = var.region
  repository_id = "compressor-api"
  description   = "compressor api repository"
  format        = "DOCKER"
}