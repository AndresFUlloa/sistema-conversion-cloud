locals {
  instance_image        = "debian-cloud/debian-10"
  instance_type         = "f1-micro"
  instance_size         = 10
  testing_instance_type = "n1-highcpu-16"

  database_user     = "app"
  project_id        = "andes-384517"
  web_api_image_uri = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.flask-api.name}/api:latest"
}