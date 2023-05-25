output "webserver_public_ip" {
  value = google_cloud_run_service.web.status[0].url
}

output "worker_public_ip" {
  value = google_cloud_run_service.worker.status[0].url
}

output "locust_public_ip" {
  value = google_compute_instance.locust.network_interface[0].access_config[0].nat_ip
}

output "database_public_ip" {
  value = google_sql_database_instance.postgresql_instance.ip_address.0.ip_address
}

output "database_public_password" {
  value     = random_password.postgresql_password.result
  sensitive = true
}