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

resource "google_compute_firewall" "web_server_firewall" {
  name    = "web-server-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "5000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = google_compute_instance_template.web_server.tags
}

data "google_compute_image" "debian" {
  family  = "debian-10"
  project = "debian-cloud"
}

resource "google_compute_instance_template" "web_server" {
  name           = "web-server-template"
  machine_type   = local.instance_type
  can_ip_forward = false

  tags = ["web-server"]

  disk {
    source_image = data.google_compute_image.debian.id
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
      software-properties-common

    # Set environment variables
    mkdir -p .envs/.local
    echo "CLOUD_STORAGE_BUCKET=${google_storage_bucket.files.name}" >> .envs/.local/.flask
    echo "POSTGRES_HOST=${google_sql_database_instance.postgresql_instance.ip_address.0.ip_address}" >> .envs/.local/.flask
    echo "POSTGRES_PORT=5432" >> .envs/.local/.flask
    echo "POSTGRES_DB=${google_sql_database.app_db.name}" >> .envs/.local/.flask
    echo "POSTGRES_USER=${google_sql_user.app_user.name}" >> .envs/.local/.flask
    echo "POSTGRES_PASSWORD=${google_sql_user.app_user.password}" >> .envs/.local/.flask
    echo "GOOGLE_CLOUD_PROJECT=${local.project_id}" >> .envs/.local/.flask

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

    sudo apt update && apt-cache policy docker-ce && sudo apt install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io

    sudo gcloud auth print-access-token | sudo docker login -u oauth2accesstoken --password-stdin us-east1-docker.pkg.dev
    sudo docker run --env-file ./.envs/.local/.flask -e FLASK_APP="compressor.app:create_app" -e APP_SETTINGS="compressor.config.DevelopmentConfig" ${local.web_api_image_uri} flask db upgrade
    sudo docker run -d -p 80:5000 --env-file ./.envs/.local/.flask -e FLASK_APP="compressor.app:create_app" -e APP_SETTINGS="compressor.config.DevelopmentConfig" -e FLASK_DEBUG=1 ${local.web_api_image_uri} gunicorn -b 0.0.0.0:5000 compressor.wsgi:app
  EOF

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = google_service_account.allow_zipped_app.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_artifact_registry_repository.flask-api
  ]
}

resource "google_compute_instance_group_manager" "web_server" {
  name = "web-server-group-manager"
  zone = var.instance_zone

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.web_server.id
    name              = "primary"
  }

  base_instance_name = "autoscaler-web-server"
  target_size        = 3

  lifecycle {
    ignore_changes = [
      target_size,
    ]
  }
}

resource "google_compute_autoscaler" "web_server" {
  name   = "web-server-autoscaler"
  zone   = var.instance_zone
  target = google_compute_instance_group_manager.web_server.id

  autoscaling_policy {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 180

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_firewall" "worker_firewall" {
  name    = "worker-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "5555", "5672", "15672"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = google_compute_instance_template.worker.tags
}

resource "google_compute_instance_template" "worker" {
  name           = "worker-template"
  machine_type   = local.instance_type
  can_ip_forward = false

  tags = ["worker"]

  disk {
    source_image = data.google_compute_image.debian.id
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
      software-properties-common

    # Set environment variables
    mkdir -p .envs/.local
    echo "CLOUD_STORAGE_BUCKET=${google_storage_bucket.files.name}" >> .envs/.local/.flask
    echo "POSTGRES_HOST=${google_sql_database_instance.postgresql_instance.ip_address.0.ip_address}" >> .envs/.local/.flask
    echo "POSTGRES_PORT=5432" >> .envs/.local/.flask
    echo "POSTGRES_DB=${google_sql_database.app_db.name}" >> .envs/.local/.flask
    echo "POSTGRES_USER=${google_sql_user.app_user.name}" >> .envs/.local/.flask
    echo "POSTGRES_PASSWORD=${google_sql_user.app_user.password}" >> .envs/.local/.flask
    echo "GOOGLE_CLOUD_PROJECT=${local.project_id}" >> .envs/.local/.flask

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

    sudo apt update && apt-cache policy docker-ce && sudo apt install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io

    sudo gcloud auth print-access-token | sudo docker login -u oauth2accesstoken --password-stdin us-east1-docker.pkg.dev
    sudo docker run -d --env-file ./.envs/.local/.flask -e FLASK_APP="compressor.app:create_app" -e APP_SETTINGS="compressor.config.DevelopmentConfig" -e FLASK_DEBUG=1 ${local.web_api_image_uri} python manage.py run_worker
  EOF

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = google_service_account.allow_zipped_app.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_artifact_registry_repository.flask-api
  ]
}

resource "google_compute_instance_group_manager" "worker" {
  name = "worker-group-manager"
  zone = var.instance_zone

  version {
    instance_template = google_compute_instance_template.worker.id
    name              = "primary"
  }

  base_instance_name = "autoscaler-worker"
  target_size        = 3

  lifecycle {
    ignore_changes = [
      target_size,
    ]
  }
}

resource "google_compute_autoscaler" "worker" {
  name   = "worker-autoscaler"
  zone   = var.instance_zone
  target = google_compute_instance_group_manager.worker.id

  autoscaling_policy {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 180

    cpu_utilization {
      target = 0.5
    }
  }
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