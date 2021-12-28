variable "project-id" {
  type = string
}

variable "instance-name" {
  type        = string
  description = "Name of instance"
}

variable "subnetwork" {
  type = string
}

variable "zone" {
  type    = string
  default = ""
}

variable "service-account-name" {
  type    = string
  default = "svc-wireguard"
}

variable "machine-family" {
  type        = string
  description = "Machine type to deploy server on"
  default     = "e2-micro"
}

variable "machine-image" {
  type        = string
  description = "Machine OS Image"
  default     = "debian-cloud/debian-11"
}

variable "ssh-auth-key" {
  type    = string
  default = ""
}

variable "wireguard_ip_range" {
  type    = string
  default = "192.168.2.0/24"
}

variable "source-ranges" {
  type        = list(string)
  description = "Range of IPs allowed through the GCP firewall"
}

variable "wg_peers" {
  type = list(string)
}

variable "wg_priv_key" {
  type      = string
  sensitive = true
}

variable "listen-port" {
  type    = number
  default = 51820
}
