provider "google" {
  credentials = "${file("service-account.json")}"
  project     = "${var.project_name}"
  region      = "us-central1"
}
