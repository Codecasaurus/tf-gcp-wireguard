output "project_id" {
  value = google_project.wireguard-project.project_id
}
output "subnetwork" {
  value = google_compute_subnetwork.wireguard-subnetwork.self_link
}
output "wireguard_ip_range" {
  value = var.wireguard_ip_range
}