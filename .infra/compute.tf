resource "google_service_account" "allow_zipped_app" {
  account_id   = "allow-zip-sa"
  display_name = "Allow Zip Account"
}

resource "google_storage_bucket_iam_binding" "allow_files_admin" {
  bucket = google_storage_bucket.files.name
  role   = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.allow_zipped_app.email}"
  ]
}

resource "google_artifact_registry_repository_iam_binding" "allow_artifact_read" {
  project    = google_artifact_registry_repository.flask-api.project
  location   = google_artifact_registry_repository.flask-api.location
  repository = google_artifact_registry_repository.flask-api.name
  role       = "roles/artifactregistry.reader"
  members = [
    "serviceAccount:${google_service_account.allow_zipped_app.email}"
  ]
}

resource "google_pubsub_subscription_iam_binding" "allow_zipped_app" {
  role         = "roles/pubsub.subscriber"
  subscription = google_pubsub_subscription.compress.name
  members = [
    "serviceAccount:${google_service_account.allow_zipped_app.email}"
  ]
}

resource "google_pubsub_topic_iam_binding" "allow_zipped_app" {
  role  = "roles/pubsub.publisher"
  topic = google_pubsub_topic.compress.name
  members = [
    "serviceAccount:${google_service_account.allow_zipped_app.email}"
  ]
}

resource "google_storage_bucket_iam_binding" "allow_zipped_app" {
  bucket = var.gcs_bucket_name
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_service_account.allow_zipped_app.email}"
  ]
}

resource "google_storage_bucket_iam_member" "allow_zipped_app" {
  bucket = var.gcs_bucket_name
  role   = "roles/storage.objectViewer"

  member = "serviceAccount:${google_service_account.allow_zipped_app.email}"
}

data "google_compute_image" "debian" {
  family  = "debian-10"
  project = "debian-cloud"
}


resource "google_project_service" "cloudrun_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloud_run_service_iam_binding" "binding" {
  location = google_cloud_run_service.web.location
  service  = google_cloud_run_service.web.name
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}


resource "google_project_service_identity" "pubsub_agent" {
  provider = google-beta
  project  = var.project
  service  = "pubsub.googleapis.com"
}

resource "google_project_iam_binding" "project_token_creator" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  members = ["serviceAccount:${google_project_service_identity.pubsub_agent.email}"]
}

resource "google_cloud_run_service" "web" {
  name     = "web-server"
  location = var.region

  template {
    spec {
      containers {
        image = local.web_api_image_uri

        ports {
          container_port = 5000
        }

        env {
          name  = "FLASK_APP"
          value = "compressor.app:create_app"
        }

        env {
          name  = "APP_SETTINGS"
          value = "compressor.config.DevelopmentConfig"
        }

        env {
          name  = "FLASK_DEBUG"
          value = 1
        }

        env {
          name  = "CLOUD_STORAGE_BUCKET"
          value = google_storage_bucket.files.name
        }

        env {
          name  = "POSTGRES_HOST"
          value = google_sql_database_instance.postgresql_instance.ip_address.0.ip_address
        }

        env {
          name  = "POSTGRES_PORT"
          value = "5432"
        }

        env {
          name  = "POSTGRES_DB"
          value = google_sql_database.app_db.name
        }

        env {
          name  = "POSTGRES_USER"
          value = google_sql_user.app_user.name
        }

        env {
          name  = "POSTGRES_PASSWORD"
          value = google_sql_user.app_user.password
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = local.project_id
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.cloudrun_api]
}

resource "google_cloud_run_service_iam_binding" "worker_binding" {
  location = google_cloud_run_service.worker.location
  service  = google_cloud_run_service.worker.name
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}

resource "google_cloud_run_service" "worker" {
  name     = "worker"
  location = var.region

  template {
    spec {

      containers {
        image = local.web_api_image_uri

        ports {
          container_port = 5000
        }

        env {
          name  = "FLASK_APP"
          value = "compressor.app:create_app"
        }

        env {
          name  = "APP_SETTINGS"
          value = "compressor.config.DevelopmentConfig"
        }

        env {
          name  = "FLASK_DEBUG"
          value = 1
        }

        env {
          name  = "CLOUD_STORAGE_BUCKET"
          value = google_storage_bucket.files.name
        }

        env {
          name  = "POSTGRES_HOST"
          value = google_sql_database_instance.postgresql_instance.ip_address.0.ip_address
        }

        env {
          name  = "POSTGRES_PORT"
          value = "5432"
        }

        env {
          name  = "POSTGRES_DB"
          value = google_sql_database.app_db.name
        }

        env {
          name  = "POSTGRES_USER"
          value = google_sql_user.app_user.name
        }

        env {
          name  = "POSTGRES_PASSWORD"
          value = google_sql_user.app_user.password
        }

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = local.project_id
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.cloudrun_api]
}


resource "google_compute_firewall" "locust_firewall" {
  name    = "locust-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "8089"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = google_compute_instance.locust.tags
}

resource "google_compute_instance" "locust" {
  name         = "locust-instance"
  machine_type = local.testing_instance_type
  zone         = var.instance_zone

  boot_disk {
    initialize_params {
      size  = local.instance_size
      image = local.instance_image
    }
  }

  allow_stopping_for_update = true

  service_account {
    email  = google_service_account.allow_zipped_app.email
    scopes = ["storage-ro"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash

    # install docker and docker-compose
    sudo apt update && sudo apt install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      gnupg-agent \
      software-properties-common \
      unzip \
      nfs-common

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

    sudo apt update && apt-cache policy docker-ce && sudo apt install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io

    curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    gsutil cp gs://${var.gcs_bucket_name}/${var.gcs_zip_file_name} /
    unzip file\:/${var.gcs_zip_file_name}

    docker-compose -f production.locust.yml up -d
  EOF

  network_interface {
    network = "default"
    access_config {}
  }
  tags = ["locust"]
}