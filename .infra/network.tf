resource "google_compute_backend_service" "web_server_backend" {
  name = "web-server-backend"

  backend {
    group = google_compute_instance_group_manager.web_server.instance_group
  }

  health_checks         = [google_compute_http_health_check.web_server_health_check.id]
  port_name             = "http"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 60
}

resource "google_compute_http_health_check" "web_server_health_check" {
  name                = "web-server-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
  request_path        = "/api/health"
  port                = 80
}

resource "google_compute_url_map" "web_server_url_map" {
  name            = "web-server-url-map"
  default_service = google_compute_backend_service.web_server_backend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.web_server_backend.id
  }
}

resource "google_compute_target_http_proxy" "web_server_target_http_proxy" {
  name    = "web-server-target-http-proxy"
  url_map = google_compute_url_map.web_server_url_map.id
}

resource "google_compute_global_address" "web_server_static_ip" {
  name = "web-server-static-ip"
}

resource "google_compute_global_forwarding_rule" "web_server_global_forwarding_rule" {
  name                  = "web-server-global-forwarding-rule"
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  target                = google_compute_target_http_proxy.web_server_target_http_proxy.id
  ip_address            = google_compute_global_address.web_server_static_ip.id
}