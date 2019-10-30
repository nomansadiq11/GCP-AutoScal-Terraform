resource "google_compute_autoscaler" "nsadiqautoscaler" {
  name   = "nsadiq"
  zone   = "us-central1-f"
  target = "${google_compute_instance_group_manager.IGManager.self_link}"

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60
    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_network" "project-network" {
  name = "${var.vpc_name}-network"
  auto_create_subnetworks = "false"
  routing_mode = "REGIONAL"
  
}

resource "google_compute_subnetwork" "project-subnet" {
  name                     = "nsadiq-subnet"
  ip_cidr_range            = "10.0.0.0/16"
  private_ip_google_access = true
  network                  = "${google_compute_network.project-network.self_link}"
}

resource "google_compute_firewall" "project-firewall-allow-ssh" {
  name    = "${var.vpc_name}-allow-something"
  network = "${google_compute_network.project-network.self_link}"
  allow {
    protocol = "tcp"
    ports    = ["80"] 
  }
 

}

resource "google_compute_firewall" "ssh" {
  name    = "${var.vpc_name}-firewall-ssh"
  network = "${google_compute_network.project-network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["${var.vpc_name}-firewall-ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance_template" "instancetemplate" {
  name           = "nsadiq-instance-template"
  machine_type   = "n1-standard-1"
  can_ip_forward = false

  tags = ["project", "development"]

  disk {
    source_image = "${data.google_compute_image.debian_9.self_link}"
  }

  network_interface {
    network = "${google_compute_network.project-network.self_link}"
    subnetwork = "${google_compute_subnetwork.project-subnet.self_link}"
  }



  metadata = {
    Project = "development"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

#    metadata_startup_script = "echo hi > /test.txt"

}

resource "google_compute_target_pool" "targetpool" {
  name = "nsadiq-target-pool"
}

resource "google_compute_instance_group_manager" "IGManager" {
  name = "nsadiq-igm"
  zone = "us-central1-f"

  instance_template  = "${google_compute_instance_template.instancetemplate.self_link}"

  target_pools       = ["${google_compute_target_pool.targetpool.self_link}"]
  base_instance_name = "foobar"
}

data "google_compute_image" "debian_9" {
    family  = "debian-9"
    project = "debian-cloud"
}