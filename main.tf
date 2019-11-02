
resource "google_compute_instance_group" "staging_group" {
  name = "staging-instance-group"
  zone = "us-central1-c"
  instances = [ "${google_compute_instance.staging_vm.self_link}" ]
  named_port {
    name = "http"
    port = "8080"
  }

  named_port {
    name = "https"
    port = "8443"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "google_compute_image" "debian_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_instance" "staging_vm" {
  name = "staging-vm"
  machine_type = "n1-standard-1"
  zone = "us-central1-c"
  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.debian_image.self_link}"
    }
  }

  network_interface {
    network = "default"
  }
}

resource "google_compute_backend_service" "staging_service" {
  name      = "staging-service"
  port_name = "https"
  protocol  = "HTTPS"

  backend {
    group = "${google_compute_instance_group.staging_group.self_link}"
  }

  health_checks = [
    "${google_compute_https_health_check.staging_health.self_link}",
  ]
}

resource "google_compute_https_health_check" "staging_health" {
  name         = "staging-health"
  request_path = "/health_check"
}