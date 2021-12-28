variable "billing_account" {
  type      = string
  sensitive = true
}

variable "ssh-auth-key" {
  type      = string
}

variable "wg_priv_key" {
  type      = string
  sensitive = true
}

variable "wg_peers" {
  type      = list(string)
}

module "setup" {
  source = "./setup"

  billing_account    = var.billing_account
  region             = "us-east1"
  project_name       = "wireguard"
  project_id         = "wireguard"
  wireguard_ip_range = "10.201.1.0/24"
}

module "instance" {
  source = "./instance"

  project-id         = module.setup.project_id
  instance-name      = "wireguard"
  subnetwork         = module.setup.subnetwork
  zone               = "us-east1-b"
  machine-family     = "e2-micro"
  machine-image      = "ubuntu-os-cloud/ubuntu-2110"
  source-ranges      = ["0.0.0.0/0"]
  ssh-auth-key       = var.ssh-auth-key
  wireguard_ip_range = module.setup.wireguard_ip_range
  wg_priv_key        = var.wg_priv_key
  wg_peers           = var.wg_peers
}

output "ip" {
  value = module.instance.ip
}

output "port" {
  value = module.instance.port
}
