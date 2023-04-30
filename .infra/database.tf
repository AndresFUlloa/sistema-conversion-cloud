resource "random_password" "postgresql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_database_instance" "postgresql_instance" {
  name                = "postgresql-instance"
  database_version    = "POSTGRES_11"
  region              = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    backup_configuration {
      enabled = false
    }
    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "public-access"
        value = "0.0.0.0/0"
      }
    }

    location_preference {
      zone = var.instance_zone
    }
  }
}

resource "google_sql_database" "app_db" {
  name     = "app_db"
  instance = google_sql_database_instance.postgresql_instance.name
}

resource "google_sql_user" "app_user" {
  name     = local.database_user
  instance = google_sql_database_instance.postgresql_instance.name
  password = random_password.postgresql_password.result
}