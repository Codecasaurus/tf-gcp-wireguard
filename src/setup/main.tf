data "google_billing_account" "account" {
  billing_account = var.billing_account
  open            = true
}

resource "random_string" "id_suffix" {
  length  = 6
  lower   = false
  upper   = false
  special = false
}

resource "google_project" "wireguard-project" {
  name            = var.project_name
  project_id      = "${var.project_id}-${random_string.id_suffix.result}"
  billing_account = data.google_billing_account.account.id
}

locals {
  region = var.region != "" ? var.region : null
}

resource "google_project_service" "iam" {
  project = google_project.wireguard-project.project_id
  service = "iam.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "logging" {
  project = google_project.wireguard-project.project_id
  service = "logging.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "storage" {
  project = google_project.wireguard-project.project_id
  service = "storage.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "compute" {
  project = google_project.wireguard-project.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_compute_network" "wireguard-network" {
  name                    = "wireguard"
  project                 = google_project_service.compute.project
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "wireguard-subnetwork" {
  name                     = "wireguard"
  ip_cidr_range            = var.wireguard_ip_range
  project                  = google_project_service.compute.project
  network                  = google_compute_network.wireguard-network.name
  private_ip_google_access = true
  region                   = local.region
}
