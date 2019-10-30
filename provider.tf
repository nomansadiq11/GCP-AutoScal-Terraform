provider "google" {
  credentials = "${file("service-account.json")}"
  project     = "qwiklabs-gcp-00-a6d1436f0347"
  region      = "us-central1"
}
