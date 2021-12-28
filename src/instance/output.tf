output "ip" {
  value = trimspace(local.endpoint_ip)
}

output "port" {
  value = var.listen-port
}
