output "webserver_public_ip" {
  value = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}


output "worker_public_ip" {
  value = google_compute_instance.worker.network_interface[0].access_config[0].nat_ip
}

output "nfs_server_public_ip" {
  value = google_compute_instance.nfs_server.network_interface[0].access_config[0].nat_ip
}

output "locust_public_ip" {
  value = google_compute_instance.locust.network_interface[0].access_config[0].nat_ip
}

output "database_public_ip" {
  value = google_sql_database_instance.postgresql_instance.ip_address.0.ip_address
}

output "database_public_password" {
  value = random_password.postgresql_password.result
  sensitive = true
}