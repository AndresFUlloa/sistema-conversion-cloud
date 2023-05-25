resource "google_pubsub_topic" "compress" {
  name = "compress"
}

resource "google_pubsub_subscription" "compress" {
  name  = "compress_subscription"
  topic = google_pubsub_topic.compress.name
  push_config {
    push_endpoint = "${google_cloud_run_service.worker.status[0].url}/api/compress-worker"
    oidc_token {
      service_account_email = google_service_account.allow_zipped_app.email
    }
    attributes = {
      x-goog-version = "v1"
    }
  }
  depends_on = [google_cloud_run_service.worker]
}