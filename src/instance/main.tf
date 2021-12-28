data "google_project" "project" {
  project_id = var.project-id
}

resource "google_service_account" "wireguard-svc-account" {
  project      = data.google_project.project.project_id
  account_id   = var.service-account-name
  display_name = var.service-account-name
}

resource "google_storage_bucket" "wireguard-storage" {
  name     = "wireguard-storage"
  location = "US"
  project  = data.google_project.project.project_id
}

resource "google_storage_bucket_access_control" "wireguard-config-acl" {
  bucket = google_storage_bucket.wireguard-storage.id
  role   = "WRITER"
  entity = "user-${google_service_account.wireguard-svc-account.email}"
}

resource "google_storage_bucket_object" "wireguard-dir" {
  name    = "${var.instance-name}/"
  content = "NA"
  bucket  = google_storage_bucket.wireguard-storage.id
}

locals {
  config-file-name = "wg0-gcp.conf"
  service-name     = split(".", local.config-file-name)[0]
  wg_cidr          = split("/", var.wireguard_ip_range)[1]
  wg_address       = "${cidrhost(var.wireguard_ip_range, 3)}/${local.wg_cidr}"
  wg_config = templatefile("${path.module}/wg0-gcp.conf", {
    wg_address     = local.wg_address,
    wg_listen_port = var.listen-port,
    wg_priv_key    = var.wg_priv_key,
    cidr           = var.wireguard_ip_range,
    peers          = var.wg_peers
  })
}

resource "google_storage_bucket_object" "config-file" {
  name    = "${var.instance-name}/${local.config-file-name}"
  content = local.wg_config
  bucket  = google_storage_bucket.wireguard-storage.id
}

resource "google_storage_bucket_iam_member" "wireguard-svc-storage" {
  bucket = google_storage_bucket.wireguard-storage.id
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.wireguard-svc-account.email}"
}

resource "google_project_iam_member" "wireguard-svc-logwriter" {
  project = data.google_project.project.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.wireguard-svc-account.email}"
}

data "google_compute_subnetwork" "wireguard-subnetwork" {
  self_link = var.subnetwork
}

resource "google_compute_address" "external-address" {
  project      = data.google_project.project.project_id
  name         = "wireguard-external-ip"
  region       = data.google_compute_subnetwork.wireguard-subnetwork.region
  address_type = "EXTERNAL"
  network_tier = "STANDARD"
}

data "google_compute_zones" "zones" {
  project = data.google_project.project.project_id
  region  = data.google_compute_subnetwork.wireguard-subnetwork.region
  status  = "UP"
}

resource "random_shuffle" "zone" {
  input = data.google_compute_zones.zones.names
}

locals {
  zone = var.zone != "" ? var.zone : random_shuffle.zone.result[0]
}

resource "google_compute_firewall" "wireguard-firewall" {
  project = data.google_project.project.project_id
  name    = "wireguard-firewall"
  network = data.google_compute_subnetwork.wireguard-subnetwork.network

  direction = "INGRESS"
  priority  = 5
  allow {
    protocol = "udp"
    ports    = [var.listen-port]
  }
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = var.source-ranges
  target_tags   = ["wg"]
}


data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-init.yaml"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init.yml", {
      ssh-auth-key  = var.ssh-auth-key,
      bucket        = google_storage_bucket.wireguard-storage.id,
      instance-name = var.instance-name,
      config-file   = local.config-file-name,
      service-name  = local.service-name
    })
  }
}

resource "google_compute_instance" "wireguard-compute" {
  project = data.google_project.project.project_id
  name    = var.instance-name
  zone    = local.zone

  tags         = ["wg"]
  machine_type = var.machine-family

  can_ip_forward = true

  network_interface {
    subnetwork = data.google_compute_subnetwork.wireguard-subnetwork.self_link
    access_config {
      nat_ip       = google_compute_address.external-address.address
      network_tier = "STANDARD"
    }
  }

  boot_disk {
    initialize_params {
      image = var.machine-image
    }
  }

  metadata = {
    user-data = data.cloudinit_config.config.rendered
  }
  metadata_startup_script = <<EOF
    exit 0
    #${sha256(data.cloudinit_config.config.rendered)}
  EOF

  service_account {
    email  = google_service_account.wireguard-svc-account.email
    scopes = ["cloud-platform", "storage-ro", "logging-write"]
  }
}

locals {
  endpoint_ip = google_compute_address.external-address.address
}
