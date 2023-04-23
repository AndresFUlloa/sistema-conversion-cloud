resource "google_service_account" "allow_zipped_app" {
  account_id   = "allow-zip-sa"
  display_name = "Allow Zip Account"
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
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = google_compute_instance.web_server.tags
}

resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = local.instance_type
  boot_disk {
    initialize_params {
      size  = local.instance_size
      image = local.instance_image
    }
  }

  zone = var.instance_zone

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

    sudo mount ${google_compute_instance.nfs_server.network_interface[0].access_config[0].nat_ip}:/mnt/nfs /mnt/nfs

    # Set environment variables
    mkdir -p .envs/.local
    echo "POSTGRES_HOST=${google_sql_database_instance.postgresql_instance.ip_address.0.ip_address}" >> .envs/.local/.flask
    echo "POSTGRES_PORT=5432" >> .envs/.local/.flask
    echo "POSTGRES_DB=${google_sql_database.app_db.name}" >> .envs/.local/.flask
    echo "POSTGRES_USER=${google_sql_user.app_user.name}" >> .envs/.local/.flask
    echo "POSTGRES_PASSWORD=${google_sql_user.app_user.password}" >> .envs/.local/.flask
    echo "CELERY_BROKER=amqp://guest:guest@${google_compute_instance.worker.network_interface[0].access_config[0].nat_ip}/" >> .envs/.local/.flask

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

    sudo apt update && apt-cache policy docker-ce && sudo apt install -y \
      docker-ce \
      docker-ce-cli \
      containerd.io

    curl -L https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Download the application and run Docker Compose
    gsutil cp gs://${var.gcs_bucket_name}/${var.gcs_zip_file_name} /
    unzip file\:/${var.gcs_zip_file_name}

    docker-compose -f production.web-server.yml run --rm app flask db upgrade
    docker-compose -f production.web-server.yml up -d
  EOF

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["web-server"]


  depends_on = [
    google_compute_instance.worker,
    google_compute_instance.nfs_server
  ]
}


resource "google_compute_firewall" "worker_firewall" {
  name    = "worker-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "5555", "5673",  "15672"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = google_compute_instance.worker.tags
}

resource "google_compute_instance" "worker" {
  name         = "worker"
  machine_type = local.instance_type
  boot_disk {
    initialize_params {
      size  = local.instance_size
      image = local.instance_image
    }
  }

  zone = var.instance_zone

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

    sudo mount ${google_compute_instance.nfs_server.network_interface[0].access_config[0].nat_ip}:/mnt/nfs /mnt/nfs

    # Set environment variables
    mkdir -p .envs/.local
    echo "POSTGRES_HOST=${google_sql_database_instance.postgresql_instance.ip_address.0.ip_address}" >> .envs/.local/.flask
    echo "POSTGRES_PORT=5432" >> .envs/.local/.flask
    echo "POSTGRES_DB=${google_sql_database.app_db.name}" >> .envs/.local/.flask
    echo "POSTGRES_USER=${google_sql_user.app_user.name}" >> .envs/.local/.flask
    echo "POSTGRES_PASSWORD=${google_sql_user.app_user.password}" >> .envs/.local/.flask
    echo "CELERY_BROKER=amqp://guest:guest@rabbitmq/" >> .envs/.local/.flask

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

    docker-compose -f production.worker.yml up -d
  EOF

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["worker"]

}

resource "google_compute_firewall" "nfs_server" {
  name    = "nfs-server-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2049", "111", "20048"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = google_compute_instance.worker.tags
}

resource "google_service_account" "default" {
  account_id   = "nfs-server-sa"
  display_name = "Service Account"
}

resource "google_compute_instance" "nfs_server" {
  name         = "nfs-server"
  machine_type = local.instance_type

  boot_disk {
    initialize_params {
      size  = local.instance_size
      image = local.instance_image
    }
  }

  zone = var.instance_zone

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["nfs-server"]

  service_account {
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nfs-kernel-server
    mkdir -p /mnt/nfs
    chmod 777 /mnt/nfs
    echo "/mnt/nfs *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
    exportfs -a
  EOF
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
  zone = var.instance_zone

  boot_disk {
    initialize_params {
      size  = local.instance_size
      image = local.instance_image
    }
  }

  metadata_startup_script = <<-EOF
    sudo apt-get update
    sudo apt-get install -y python3-pip

    sudo pip3 install locust
  EOF

  network_interface {
    network = "default"
    access_config {}
  }
  tags = ["locust"]
}